# =============================================================================
# Wine / Proton 助手（移植自 ~/.dotfiles/zsh/wine.zsh）
# =============================================================================
# Steam 自带的 Proton 10.0（umu 和 play 共用）
set -gx STEAM_PROTON10 "$HOME/.local/share/Steam/steamapps/common/Proton 10.0"

# umu：用 Steam 的 Proton 跑 Windows 程序（经 umu-launcher）
#   umu xxx.exe              用默认前缀 ~/Games/umu/umu-default
#   umu -n myname xxx.exe    用 ~/Games/umu/myname 前缀（不存在时自动建）
#                            名字和 play 的别名同一套，不要加引号
#   umu -n myname -- xxx.exe 程序自己的 -n 参数写在 -- 后面
function umu --description "用 Steam 的 Proton 跑 Windows 程序"
    set -l name
    set -l args
    set -l i 1
    set -l total (count $argv)

    while test $i -le $total
        switch $argv[$i]
            case -n
                if test $i -ge $total
                    echo 'umu：-n 后面要跟前缀名，例如 umu -n xunlei xxx.exe' >&2
                    return 1
                end
                set name $argv[(math $i + 1)]
                set i (math $i + 2)
            case --
                while test $i -lt $total
                    set i (math $i + 1)
                    set -a args $argv[$i]
                end
                break
            case '*'
                set -a args $argv[$i]
                set i (math $i + 1)
        end
    end

    # 只接受单层目录名，防止 ../ 之类把前缀建到别处
    if test -n "$name"
        if string match -q -- '*/*' $name; or string match -q -- '.*' $name
            echo "umu：前缀名不能含 / 或以 . 开头：$name" >&2
            return 1
        end
    end

    if test -n "$name"
        env WINEPREFIX="$HOME/Games/umu/$name" PROTONPATH="$STEAM_PROTON10" umu-run $args
    else
        env PROTONPATH="$STEAM_PROTON10" umu-run $args
    end
end
