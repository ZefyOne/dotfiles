# niri 下 WPS 右键菜单「聚在屏幕中间」——原因与修复

> 一份可复制的操作手册。已在 niri 26.04 + xwayland-satellite 0.8.3 + WPS Office CN 12.1.2 + labwc 0.20.2 上实测通过。

---

## 1. 症状

在 niri 里用 WPS 文字，右键想弹菜单，结果：

- 菜单不在鼠标处，而是跑到**屏幕正中央**；
- 有时候**两个**菜单同时叠在中间（其实是「右键菜单 + 迷你工具条」两个窗口）；
- 菜单还会抢焦点、出现在 Alt+Tab 列表里。

命令行验证：右键一次后执行

```bash
niri msg --json windows | jq -r '.[] | select(.app_id=="wps")'
```

会看到凭空多出一个 `app_id=wps`、`is_floating=true`、`title=wps` 的浮动窗口，位置正好是屏幕中心。

---

## 2. 原因

一句话：**WPS 把右键菜单做成了一个普通 X11 顶层窗口，而 niri 没有「让窗口出现在屏幕某个坐标」这个概念。**

拆开说：

1. **WPS 是纯 X11 程序。** 自带 Qt 5.12.12，平台插件目录里只有 `libqxcb.so`，没有 QtWayland。所以它通过 XWayland 以 X11 客户端身份运行。

   ```bash
   ls /usr/lib/office6/qt/plugins/platforms/     # 只有 libqxcb.so / libqskia.so
   ```

2. **菜单窗口不是「弹出窗口」。** 实测其属性是：

   ```
   _NET_WM_WINDOW_TYPE = [_KDE_NET_WM_WINDOW_TYPE_OVERRIDE, _NET_WM_WINDOW_TYPE_NORMAL]
   override_redirect  = False
   ```

   它靠传统 X11 的做法：创建普通窗口，再用 `ConfigureWindow` 把自己挪到鼠标位置。

3. **xwayland-satellite 按类型判定角色。** 源码 `guess_window_role()` 里，`override_redirect=true` 才判为 Popup，否则遇到 `_NET_WM_WINDOW_TYPE_NORMAL` 直接判为 **Toplevel**。于是 niri 收到的是一个正经窗口。

4. **niri 会居中摆放新浮动窗口。** 顶层窗口的移动请求被忽略，新窗口由合成器决定位置 → 正中。菜单有几个，就叠几个。

> 这是 niri 的结构性限制（官方 Xwayland 文档也写明：会自己摆屏幕坐标的 X11 程序需要嵌套合成器），**纯靠 niri 配置规则治不好**——窗口规则里只有静态的 `default-floating-position`，没有「跟随鼠标」。

---

## 3. 判据（换机器时先确认）

三条全中，再动手：

```bash
# ① WPS 没有 Wayland 后端
ls /usr/lib/office6/qt/plugins/platforms/

# ② 右键后有 app_id=wps 的浮动窗口
niri msg --json windows | jq -r '.[] | select(.app_id=="wps" and .is_floating)'

# ③ 该窗口位置在屏幕中心（2560x1440 时约为 [1170,603]）
niri msg --json windows | jq '.[] | select(.app_id=="wps" and .is_floating) | .layout.tile_pos_in_workspace_view'
```

> **例外**：若 ① 里出现了 `libqwayland*.so`，说明新版 WPS 支持 Wayland，直接 `QT_QPA_PLATFORM=wayland wps` 即可，本方案不用做。

---

## 4. 修复方案：用嵌套 labwc 包一层

思路：把 WPS 放进一个嵌套的 labwc（真正的窗口管理器）里跑。菜单窗口在 labwc 内部被正常定位，niri 只看到一个外框窗口。

一共 5 步。

### ① 安装 labwc

```bash
sudo pacman -S labwc          # Arch
# sudo apt install labwc      # Debian / Ubuntu
```

### ② 两个包装脚本

```bash
mkdir -p ~/.local/bin
```

**`~/.local/bin/wps-nested`**（入口）：

```bash
#!/usr/bin/env bash
# 在嵌套的 labwc 合成器里运行 WPS 系列程序。
# 原因：niri 无法按屏幕坐标放置顶层窗口，WPS 的右键菜单会被当成普通窗口居中。
# 用法：wps-nested [wps|et|wpp|wpspdf] [文件...]
set -u

app="wps"; label="WPS 文字"
if [ $# -gt 0 ]; then
    case "$1" in
        wps)     app="wps";     label="WPS 文字"; shift ;;
        et)      app="et";      label="WPS 表格"; shift ;;
        wpp)     app="wpp";     label="WPS 演示"; shift ;;
        wpspdf)  app="wpspdf";  label="WPS PDF";  shift ;;
    esac
fi

if ! command -v labwc >/dev/null 2>&1; then
    echo "wps-nested: 需要先安装 labwc（sudo pacman -S labwc）" >&2
    exit 1
fi

if [ $# -gt 0 ]; then
    cmd="$app$(printf ' %q' "$@")"
else
    cmd="$app"
fi

inner="$HOME/.local/bin/wps-nested-inner"
exec labwc -t "$label" -S "dbus-run-session -- $inner $cmd"
```

**`~/.local/bin/wps-nested-inner`**（会话内先起输入法）：

```bash
#!/usr/bin/env bash
# 由 wps-nested 在 labwc 会话内调用：先起一个本会话私有的 fcitx5，
# 再启动 WPS。这样候选/预编辑窗口作为 labwc 的客户端渲染，
# 不会跑到 niri 里变成独立窗口。
set -u

if command -v fcitx5 >/dev/null 2>&1; then
    fcitx5 -d >/dev/null 2>&1 || true
    # 给 fcitx5 一点时间注册 XIM / DBus
    sleep 1
fi

exec "$@"
```

赋权并检查语法：

```bash
chmod +x ~/.local/bin/wps-nested ~/.local/bin/wps-nested-inner
bash -n ~/.local/bin/wps-nested && bash -n ~/.local/bin/wps-nested-inner && echo OK
```

> 为什么要第二个脚本 + `dbus-run-session`：WPS 通过 D-Bus 连输入法。若复用外层 fcitx5，候选框会成为 niri 的独立窗口；放进私有 D-Bus 会话后，fcitx5 和 WPS 都在 labwc 里，候选框跟着 WPS 窗口走。

### ③ `~/.config/labwc/rc.xml`

```bash
mkdir -p ~/.config/labwc
```

```xml
<?xml version="1.0"?>
<labwc_config>
  <core>
    <gap>0</gap>
    <xwaylandPersistence>yes</xwaylandPersistence>
  </core>
  <theme>
    <name>Default</name>
    <border width="0" />
  </theme>
  <placement>
    <policy>automatic</policy>
  </placement>
  <windowRules>
    <!-- 只最大化「本次会话第一个映射的 WPS 窗口」，即主窗口。
         后面的菜单 / 工具条 / 对话框保持原样。 -->
    <windowRule identifier="wps" title="*" matchOnce="true">
      <action name="Maximize" />
    </windowRule>
  </windowRules>
</labwc_config>
```

> 校验：`python3 -c "import xml.dom.minidom;xml.dom.minidom.parse('$HOME/.config/labwc/rc.xml')"`

### ④ 覆盖桌面入口（用户级，不动系统文件）

```bash
mkdir -p ~/.local/share/applications

# 找出所有启动 WPS 的 desktop 文件
grep -l '^Exec=.*wps' /usr/share/applications/*.desktop
```

对每个文件，复制到用户目录并把 `Exec` 换成包装脚本。例如 wps 文字：

```bash
sed 's|^Exec=/usr/bin/wps|Exec='"$HOME"'/.local/bin/wps-nested wps|' \
    /usr/share/applications/wps-office-wps.desktop \
    > ~/.local/share/applications/wps-office-wps.desktop
```

其余同理，把「`/usr/bin/wps` → `wps %U`」换成对应程序：

| 原 Exec | 改成 |
|---|---|
| `/usr/bin/wps %U` | `$HOME/.local/bin/wps-nested wps %U` |
| `/usr/bin/et %F` | `$HOME/.local/bin/wps-nested et %F` |
| `/usr/bin/wpp %F` | `$HOME/.local/bin/wps-nested wpp %F` |
| `/usr/bin/wpspdf %F` | `$HOME/.local/bin/wps-nested wpspdf %F` |

刷新缓存：

```bash
update-desktop-database ~/.local/share/applications
```

### ⑤ niri 窗口规则

写进 `~/.config/niri/__custom__.kdl`（别写主 config，升级会被覆盖）：

```kdl
window-rule {
    match app-id=r#"^labwc$"#
    open-maximized true
}
```

niri 会自动监听配置变化，保存即生效（也可 `niri validate` 检查）。

---

## 5. 验证

1. 从应用菜单启动「WPS 文字」，应当出现一个铺满的窗口（标题在 niri 里显示为 `WPS 文字`，`app_id=labwc`）。
2. 右键文档区域：菜单应出现在**鼠标附近**，而不是屏幕中心。
3. `niri msg --json windows` 里**不应**再出现 `title=wps` 的浮动窗口。
4. 输入中文：候选框应出现在 WPS 窗口内部、跟随光标。

如果第 4 条不对，见下面「坑」。

---

## 6. 踩过的坑

| 现象 | 原因 | 解法 |
|---|---|---|
| 四周一大片黑边 | WPS 窗口只有 1222×1330，labwc 画布 2536×1370，空出来的地方是 labwc 黑底 | 加 `Maximize` 规则（第 ③ 步） |
| 菜单也变成满屏、点击被吞 | 规则只写 `identifier="wps"`，把菜单窗口也最大化了 | 必须加 `title="*"` + `matchOnce="true"` |
| 规则完全不生效 | 只写 `matchOnce="true"`，没给 `title` | `matchOnce` 需要配合 `title` 才生效 |
| 候选框变成 niri 里的独立窗口 | 复用外层 fcitx5，它的 UI 没有可依附的 surface | 用 `dbus-run-session` + 会话内 fcitx5（第 ② 步） |
| `gio launch xxx.desktop` 测试失败、报 `unable to open wayland socket` | 在受限环境里执行，拿不到渲染节点 | 别用 `gio launch` 验证，直接从菜单启动 |
| 启动后提示「上次未正常关闭」 | 测试时强杀过 labwc | 忽略，点掉即可 |

---

## 7. 回滚

```bash
rm ~/.local/bin/wps-nested ~/.local/bin/wps-nested-inner
rm ~/.config/labwc/rc.xml
rm ~/.local/share/applications/wps-office-*.desktop
update-desktop-database ~/.local/share/applications
```

再删掉 `__custom__.kdl` 里那段 `window-rule`；不想要 labwc 了可 `sudo pacman -Rns labwc`。

回滚后 WPS 恢复「菜单居中」的老状态——功能不受损，只是菜单位置错。

---

## 8. 换发行版 / 换机器的差异点

| 项 | 说明 |
|---|---|
| WPS 安装路径 | Arch 包在 `/usr/lib/office6`；官方 deb/rpm 常在 `/opt/kingsoft/wps-office/office6`。脚本走 `PATH` 里的 `wps`，一般无需改 |
| desktop 文件名 | 各发行版不同，用 `grep -l '^Exec=.*wps' /usr/share/applications/*.desktop` 找，别硬记 |
| 输入法 | 必须「私有 D-Bus + 会话内 fcitx5」，否则候选框逃到外层 |
| 没有 labwc | 退而求其次 `cage -- wps`（对话框会被全屏吞掉，体验差） |

---

## 9. 备选方案（不想折腾时）

- **忍**：菜单位置错，但功能正常。
- **换软件**：LibreOffice / OnlyOffice 是 Wayland 原生，没有此问题。
- **上报 WPS**：正确做法是让 WPS 把菜单窗口标成 `_NET_WM_WINDOW_TYPE_POPUP_MENU` 或设 override-redirect；上游改了就不用这套了。

---

## 10. 排查命令速查

```bash
# 列出所有 X 显示及其上的 XIM 服务（找嵌套会话的显示号、判断输入法是否在内层）
for n in 0 1 2 3 4 5; do
  DISPLAY=:$n xdpyinfo >/dev/null 2>&1 && {
    echo ":$n"
    DISPLAY=:$n xprop -root XIM_SERVERS 2>/dev/null
  }
done

# 看某个显示上 WPS 的窗口属性
DISPLAY=:2 xwininfo -root -tree | grep -i wps

# niri 侧窗口列表
niri msg --json windows | jq -r '.[] | "\(.id) \(.app_id) \(.title)"'
```
