# =============================================================================
# Nyxuri Custom Fish Configuration / 个人 fish 配置入口
# =============================================================================
# 本文件放在 dotfiles 里（~/.dotfiles/fish/），通过软链被 fish 加载：
#
#   ln -sf ~/.dotfiles/fish/__custom__.fish ~/.config/fish/conf.d/__custom__.fish
#
# 它按顺序 source 同目录下的分文件；新增模块只要在下面的列表里加一行。
# 因为入口是软链，status filename 给的是软链路径，所以先用 path resolve 取真实
# 目录，否则会去 ~/.config/fish/conf.d/ 下找分文件。
# =============================================================================

# 防止被重复 source（例如手动 source 一次 + 启动加载一次）
if set -q __custom_fish_loaded
    return
end
set -g __custom_fish_loaded 1

set -g __custom_fish_dir (path dirname (path resolve (status filename)))

# 加载顺序即列表顺序；一个 zsh 源文件对应一个 fish 文件
for __custom_fish_mod in \
        00-aliases \
        10-git \
        20-games \
        30-wine \
        40-claude \
        50-proxy \
        60-splash
    set -l mod_path $__custom_fish_dir/$__custom_fish_mod.fish
    if test -f $mod_path
        source $mod_path
    end
end

set -e __custom_fish_mod
