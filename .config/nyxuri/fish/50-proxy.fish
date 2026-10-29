# =============================================================================
# 终端代理（移植自 ~/.dotfiles/zsh/proxy.zsh）
# =============================================================================
# 实际的 proxy_on / proxy_off / proxy_status 在 config.fish 里（Nyxuri 自带），
# 这里只补 zsh 的旧名字，避免肌肉记忆失效。

function proxyon --description "开启终端代理（zsh 兼容命名）"
    proxy_on $argv
end

function proxyoff --description "关闭终端代理（zsh 兼容命名）"
    proxy_off
end

# 启动时自动开代理：等 config.fish 加载完（第一次提示符）再调 proxy_on，然后自毁。
# 想关掉自动代理，注释掉下面这一个函数即可。
function __custom_proxy_autostart --on-event fish_prompt
    functions --erase __custom_proxy_autostart
    status is-interactive; or return
    proxy_on >/dev/null 2>&1
end
