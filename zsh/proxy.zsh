PROXY_HTTP="http://127.0.0.1:7897"
PROXY_SOCKS="socks5://127.0.0.1:7897"

proxyon() {
  export http_proxy="$PROXY_HTTP"
  export https_proxy="$PROXY_HTTP"
  export all_proxy="$PROXY_SOCKS"
  export no_proxy="localhost,127.0.0.1"
  echo "[proxy] 已开启"
}

proxyoff() {
  unset http_proxy https_proxy all_proxy no_proxy
  echo "[proxy] 已关闭"
}
