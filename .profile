# 仅当 vicinae server 未运行时启动
if ! pgrep -f "vicinae server" >/dev/null 2>&1; then
  vicinae server >/dev/null 2>&1 &
fi
