# =============================================================================
# 游戏一键启动器（移植自 ~/.dotfiles/zsh/games.zsh）
# =============================================================================
#   play                列出所有游戏
#   play dong           后台启动，终端立刻可用
#   play dong --debug   占住终端，实时显示输出
#
# 格式：'别名|类型|目录|目标|描述'
#   类型   native = 直接执行目标   proton = 用 Steam 的 Proton 跑目标
#   目标   native → 启动脚本/二进制，相对「目录」
#          proton → 要跑的 exe，相对「目录」
#   描述   可选，列出时显示
# -----------------------------------------------------------------------------

set -g __games \
    'opp|native|~/.mgm/.7/0.5/0.5|./OppaiOdyssey.sh|欧派奥德赛' \
    'eter|native|~/.mgm/.7/Eternum-0.9.0-pc|./Eternum.sh|永恒世界' \
    'mil|native|~/.mgm/.7/ns/Nanviowrnzy/Nanviweornzy/电脑/Milfs.Of.Sunville.S.2.v5.00|./MilfsOfSunville.sh|熟女' \
    'pho|native|~/.mgm/.7/Phoenixes|./Phoenixes.x86_64|凤凰' \
    'vir|native|~/.mgm/.7/VIRTUES-v17a-pc|./VIRTUES.sh|美德' \
    'har|native|~/.mgm/.7/Harem_Hotel-v0.19.1-pc|./Harem_Hotel.sh|后宫酒店' \
    'dong|proton|~/.mgm/.7/fohor/冬104+/Winter Memories v1.04|Game.exe|冬日' \
    'xia|proton|~/.mgm/.7/fohor/Summer Memories v2.02.1|Game.exe|夏日' \
    'xiamo|proton|~/.mgm/.7/fohor/夏日魔改版本|Game.exe|夏日魔改版本' \
    'sum|proton|~/.mgm/.7/ns/Summer Clover/Summer Clover|Summer Clover.exe|夏色四叶草' \
    'vill|proton|~/.mgm/.7/xan/Xancwoany/Xancunwoany/Village.Rhapsody|setup.exe|乡村狂想曲' \
    'xunlei|proton|~/Games/umu/xunlei/drive_c/Program Files (x86)/Thunder Network/Thunder/Program|Thunder.exe|迅雷'

# 取某个游戏条目的第 N 段（1=别名 2=类型 3=目录 4=目标 5=描述）
function __game_field --argument-names name field
    for entry in $__games
        set -l f (string split -m 4 '|' -- $entry)
        if test "$f[1]" = "$name"
            echo $f[$field]
            return 0
        end
    end
    return 1
end

# 输出正在运行的 Proton 游戏的别名，每行一个（认不出的忽略）
function __play_running_protons
    set -l umu (command -s umu-run)
    test -n "$umu"; or set umu /usr/bin/umu-run
    for pid in (pgrep -f -- $umu 2>/dev/null)
        set -l dir (readlink /proc/$pid/cwd 2>/dev/null)
        test -z "$dir"; and continue
        for entry in $__games
            set -l f (string split -m 4 '|' -- $entry)
            set -l d (string replace -r '^~' $HOME -- $f[3])
            if test "$d" = "$dir"
                echo $f[1]
                break
            end
        end
    end
end

function play --description "游戏一键启动器（无参数列出所有游戏）"
    # 无参数 → 列出所有游戏，按类型分组、组内按别名排序
    if test (count $argv) -eq 0
        if test (count $__games) -eq 0
            echo '还没配置游戏。打开 ~/.config/fish/conf.d/__custom__/20-games.fish，按里面的格式加。'
            return 0
        end

        set -l kinds
        for entry in $__games
            set -l f (string split -m 4 '|' -- $entry)
            contains -- $f[2] $kinds; or set -a kinds $f[2]
        end

        echo '可用游戏：'
        set -l first 1
        for kind in (printf '%s\n' $kinds | sort)
            echo
            if test $first -eq 0
                echo "  "(string repeat -n 46 '-')
            end
            set first 0
            echo "  $kind："

            set -l aliases
            for entry in $__games
                set -l f (string split -m 4 '|' -- $entry)
                if test "$f[2]" = "$kind"
                    set -a aliases $f[1]
                end
            end

            for a in (printf '%s\n' $aliases | sort)
                set -l dir (__game_field $a 3)
                set -l desc (__game_field $a 5)
                echo
                printf '  %-10s %s\n' "$a" "$desc"
                printf '  %-10s %s\n' "" "$dir"
            end
        end
        return 0
    end

    set -l name $argv[1]
    set -e argv[1]

    set -l spec
    for entry in $__games
        set -l f (string split -m 4 '|' -- $entry)
        if test "$f[1]" = "$name"
            set spec $entry
            break
        end
    end
    if test -z "$spec"
        set -l all
        for entry in $__games
            set -l f (string split -m 4 '|' -- $entry)
            set -a all $f[1]
        end
        echo "play：没有叫 '$name' 的游戏（可用："(printf '%s\n' $all | sort | string join ' ')")" >&2
        return 1
    end

    set -l f (string split -m 4 '|' -- $spec)
    set -l kind $f[2]
    set -l dir (string replace -r '^~' $HOME -- $f[3])
    set -l target $f[4]
    set -l desc $f[5]
    test -n "$desc"; or set desc $name

    set -l pfx "$HOME/Games/umu/$name"

    # 每个 Proton 游戏一个独立前缀，不同游戏可同时跑；同一游戏不能开两份
    if test "$kind" = proton
        if contains -- $name (__play_running_protons)
            echo "play：'$name'（$desc）已经在跑了，先关掉它再开这个。" >&2
            return 1
        end
        if not test -d $pfx
            echo "play：'$desc' 第一次跑，正在建独立前缀（约 30 秒），别急。" >&2
        end
    end

    set -l cmd
    switch $kind
        case native
            set cmd "$target"
        case proton
            set cmd env WINEPREFIX=$pfx PROTONPATH=$STEAM_PROTON10 umu-run "$target"
        case '*'
            echo "play：未知类型 '$kind'" >&2
            return 1
    end

    # 挑出 --debug，其余原样透传给游戏
    set -l debug 0
    set -l pass
    for a in $argv
        if test "$a" = --debug
            set debug 1
        else
            set -a pass $a
        end
    end

    if not pushd $dir >/dev/null
        echo "play：进不去目录 $dir" >&2
        return 1
    end

    if test $debug -eq 1
        exec $cmd $pass
    else
        $cmd $pass >/dev/null 2>&1 &
        disown $last_pid
        popd >/dev/null
    end
end
