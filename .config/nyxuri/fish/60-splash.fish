# =============================================================================
# 启动画面（移植自 ~/.dotfiles/zsh/splash.zsh）
# =============================================================================
# pokemon-colorscripts 随机宝可梦 + fastfetch 并排显示。
# 只在交互式、且 stdout 是终端时运行；第一次提示符前执行一次后自毁。
function __custom_splash --on-event fish_prompt
    functions --erase __custom_splash
    status is-interactive; or return
    isatty stdout; or return
    command -q pokemon-colorscripts; or return
    command -q fastfetch; or return

    # 优先用 pokemon 专用配置；新版配置里没带就退回旧 dotfiles 的，再不行用默认配置
    set -l cfg "$HOME/.config/fastfetch/config-pokemon.jsonc"
    if not test -f $cfg
        set cfg "$HOME/.dotfiles/.config/fastfetch/config-pokemon.jsonc"
    end
    set -l args
    test -f $cfg; and set args -c $cfg

    pokemon-colorscripts --no-title -s -r | \
        fastfetch $args --logo-type file-raw --logo-height 10 --logo-width 5 --logo - --pipe false
end
