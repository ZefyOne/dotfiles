# fish 个人配置（dotfiles）

这些是从旧 zsh 配置迁移过来的 fish 片段。整份目录由 dotfiles 管理，
运行时通过**一个软链**接入 fish：

```fish
ln -sf ~/.dotfiles/fish/__custom__.fish ~/.config/fish/conf.d/__custom__.fish
```

## 结构

| 文件 | 来源 | 内容 |
|---|---|---|
| `__custom__.fish` | — | 入口：取真实目录，按顺序 source 下面的分文件 |
| `00-aliases.fish` | `aliass.zsh` / `path.zsh` | `n`、`y`、`c`、`cl`、`cld`、`l`、`lla`、`lt`，`EDITOR=nvim` |
| `10-git.fish` | `git.zsh` | `repos` 表 + `commit`/`push`/`pushe`/`pushb`/`pushall`/`pullall`/`commitall`/`query` |
| `20-games.fish` | `games.zsh` | `play` 游戏启动器（12 个游戏，native/proton） |
| `30-wine.fish` | `wine.zsh` | `umu`（Steam Proton 10.0，独立前缀） |
| `40-claude.fish` | `claude.zsh` | Emacs/ghostel 下清理 `CLAUDE*`，强制会话持久化 |
| `50-proxy.fish` | `proxy.zsh` | `proxyon`/`proxyoff` 兼容名 + 首提示符自动开代理 |
| `60-splash.fish` | `splash.zsh` | pokemon-colorscripts + fastfetch 启动画面 |

## 注意

- `__custom__.fish` 由 fish 作为 `conf.d` 文件自动加载；分文件**不会**被 fish 自动加载，只由入口 source。
- `conf.d` 在 `config.fish` 之前执行，因此这里无法覆盖 `config.fish` 中已定义的
  `ls`、`clear`、`up`/`in`/`se`/`un`、`nyxhelp`、`proxy_*` 等名字。
- 新增模块：在同目录建 `NN-name.fish`，再在 `__custom__.fish` 的列表里加 `NN-name`。
- `20-games.fish` 含个人游戏列表，已在 `.gitignore` 中排除（与旧的 `zsh/games.zsh` 一致）。
