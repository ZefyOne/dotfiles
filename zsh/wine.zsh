# mywine：用独立 wine 环境（~/Games/wine-games）运行 Windows 程序
# 用法：mywine xxx.exe   或   mywine 'C:\Games\xxx.exe'
mywine() {
  WINEPREFIX=~/Games/wine-games wine "$@"
}

# Steam 自带的 Proton 10.0（umu 和 play 共用）
STEAM_PROTON10="$HOME/.local/share/Steam/steamapps/common/Proton 10.0"

# umu：用 Steam 的 Proton 跑 Windows 程序（经 umu-launcher）
# 用法：umu xxx.exe
alias umu='PROTONPATH="$STEAM_PROTON10" umu-run'
