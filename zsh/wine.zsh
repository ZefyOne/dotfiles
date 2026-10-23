# mywine：用独立 wine 环境（~/Games/wine-games）运行 Windows 程序
# 用法：mywine xxx.exe   或   mywine 'C:\Games\xxx.exe'
# mywine() {
#   WINEPREFIX=~/Games/wine-games wine "$@"
# }

# Steam 自带的 Proton 10.0（umu 和 play 共用）
STEAM_PROTON10="$HOME/.local/share/Steam/steamapps/common/Proton 10.0"

# umu：用 Steam 的 Proton 跑 Windows 程序（经 umu-launcher）
#   umu xxx.exe              用默认前缀 ~/Games/umu/umu-default
#   umu -n myname xxx.exe    用 ~/Games/umu/myname 前缀（不存在时自动建）
#                            名字和 play 的别名同一套，不要加引号
# 从旧版 alias 迁移过来，先清掉老的 alias，否则它会抢在函数前面展开
unalias umu 2>/dev/null
umu() {
  local name
  local -a args
  while (( $# )); do
    case $1 in
      -n)
        if (( $# < 2 )); then
          print -u2 'umu：-n 后面要跟前缀名，例如 umu -n xunlei xxx.exe'
          return 1
        fi
        name=$2
        shift 2
        ;;
      --)
        # -- 之后全部原样透传，程序自己的 -n 参数从这后面写
        shift
        args+=("$@")
        break
        ;;
      *)
        args+=("$1")
        shift
        ;;
    esac
  done

  # 只接受单层目录名，防止 ../ 之类把前缀建到别处
  if [[ -n $name && ( $name == */* || $name == .* ) ]]; then
    print -u2 "umu：前缀名不能含 / 或以 . 开头：$name"
    return 1
  fi

  if [[ -n $name ]]; then
    WINEPREFIX="$HOME/Games/umu/$name" PROTONPATH="$STEAM_PROTON10" umu-run "${args[@]}"
  else
    PROTONPATH="$STEAM_PROTON10" umu-run "${args[@]}"
  fi
}
