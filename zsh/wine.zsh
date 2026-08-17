# mywine：用独立 wine 环境（~/Games/wine-games）运行 Windows 程序
# 用法：mywine xxx.exe   或   mywine 'C:\Games\xxx.exe'
mywine() {
  WINEPREFIX=~/Games/wine-games wine "$@"
}
