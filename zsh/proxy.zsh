# 端口只在这里改一次
# PROXY_PORT=7897
PROXY_PORT=32081

PROXY_HTTP="http://127.0.0.1:${PROXY_PORT}"
PROXY_SOCKS="socks5://127.0.0.1:${PROXY_PORT}"

proxyon() {
  export http_proxy="$PROXY_HTTP"
  export https_proxy="$PROXY_HTTP"
  export all_proxy="$PROXY_HTTP"
  export no_proxy="localhost,127.0.0.1,dl.google.com,.local"
}

proxyoff() {
  unset http_proxy https_proxy all_proxy no_proxy
  echo "[proxy] 已关闭"
}
