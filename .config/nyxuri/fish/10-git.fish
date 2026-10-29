# =============================================================================
# Git 多仓库助手（移植自 ~/.dotfiles/zsh/git.zsh）
# =============================================================================
# 仓库配置：别名|路径|远程标记（gitee / github / gitee github）
# 增删仓库只改这一处；某仓库新增远程只改该行第三段。
set -g __git_repos \
    "dotfiles|$HOME/.dotfiles|gitee github" \
    "script|$HOME/Documents/Script|gitee" \
    "know|$HOME/Documents/KnowledgeSystem|gitee github" \
    "novel|$HOME/Documents/Novel|gitee" \
    "zettelkasten|$HOME/Documents/zettelkasten|gitee"

# 取某个仓库条目的第 N 段（N: 1=别名 2=路径 3=远程标记）
function __repo_field --argument-names name field
    for entry in $__git_repos
        set -l parts (string split -m 2 '|' -- $entry)
        if test "$parts[1]" = "$name"
            echo $parts[$field]
            return 0
        end
    end
    return 1
end

# 按别名查路径 / 远程标记（找不到返回 1）
function repo_path
    __repo_field $argv[1] 2
end

function repo_remotes
    __repo_field $argv[1] 3
end

# 提交指定仓库（无参数则提交当前目录）
function commit --description "提交指定仓库或当前目录"
    set -l repo
    if test (count $argv) -eq 0
        set repo $PWD
        echo "未指定仓库，将提交当前目录：$repo"
    else
        set repo (repo_path $argv[1])
        if test -z "$repo"
            set -l names
            for entry in $__git_repos
                set -l parts (string split -m 2 '|' -- $entry)
                set -a names $parts[1]
            end
            echo "错误：未知的仓库别名 '$argv[1]'"
            echo "可用别名：$names"
            return 1
        end
    end

    cd $repo
    or return 1
    git add .
    and git commit -m (date "+%Y-%m-%d %H:%M")
end

# 提交并推送当前目录仓库到指定的一个或多个远程（参数为远程名）
function push --description "提交当前目录并推送到指定远程"
    git add .
    git commit --quiet -m (date "+%Y-%m-%d %H:%M")
    echo
    for r in $argv
        printf '    \033[1;36m→ %s\033[0m   %s\n' $r (git push $r main 2>&1 | tail -1)
    end
end

function pushe
    push gitee
end

function pushb
    push github
end

function pushall --description "提交并推送所有仓库到各自配置的远程"
    for entry in $__git_repos
        set -l parts (string split -m 2 '|' -- $entry)
        set -l dir $parts[2]
        set -l remotes $parts[3]
        printf '\033[1;33m  ── %s ──\033[0m\n' $dir
        if pushd $dir >/dev/null
            push (string split ' ' -- $remotes)
            popd >/dev/null
        end
        echo
    end
end

function pullall --description "从 gitee 拉取所有仓库（rebase）"
    for entry in $__git_repos
        set -l parts (string split -m 2 '|' -- $entry)
        set -l dir $parts[2]
        printf '\033[1;33m  ── %s ──\033[0m\n' $dir
        set -l msg (git -C $dir fetch gitee --quiet 2>&1; git -C $dir pull --rebase gitee main 2>&1 | tail -1)
        printf '    \033[1;36m→ gitee\033[0m   %s\n' $msg
        echo
    end
end

function commitall --description "提交所有仓库（不推送）"
    for entry in $__git_repos
        set -l parts (string split -m 2 '|' -- $entry)
        set -l dir $parts[2]
        printf '\033[1;33m  ── %s ──\033[0m\n' $dir
        if pushd $dir >/dev/null
            git add .
            git commit -m (date "+%Y-%m-%d %H:%M")
            popd >/dev/null
        end
        echo
    end
end

# 查询各仓库与远程的领先/落后状态（只 fetch，不做任何改动）
function query --description "查看各仓库与远程的领先/落后状态"
    for entry in $__git_repos
        set -l parts (string split -m 2 '|' -- $entry)
        set -l dir $parts[2]
        set -l remotes $parts[3]
        printf '\033[1;33m  ── %s ──\033[0m\n' $dir

        if not git -C $dir rev-parse --is-inside-work-tree >/dev/null 2>&1
            echo "    不是 git 仓库，跳过"
            echo
            continue
        end

        if test -z "$remotes"
            echo "    未配置远程，跳过"
            echo
            continue
        end

        git -C $dir fetch --all --quiet 2>&1

        set -l head_sha (git -C $dir rev-parse --short HEAD 2>/dev/null)

        for remote in (string split ' ' -- $remotes)
            set -l ref "$remote/main"
            if not git -C $dir rev-parse --verify --quiet $ref >/dev/null 2>&1
                printf '    \033[1;36m→ %s\033[0m   无 %s/main 分支\n' $remote $remote
                continue
            end

            set -l remote_sha (git -C $dir rev-parse --short $ref 2>/dev/null)
            set -l behind (git -C $dir rev-list --count HEAD..$ref 2>/dev/null)
            test -n "$behind"; or set behind 0
            set -l ahead (git -C $dir rev-list --count $ref..HEAD 2>/dev/null)
            test -n "$ahead"; or set ahead 0

            set -l state
            if test "$behind" -eq 0 -a "$ahead" -eq 0
                set state 同步
            else if test "$behind" -gt 0 -a "$ahead" -eq 0
                set state "落后 $behind"
            else if test "$behind" -eq 0 -a "$ahead" -gt 0
                set state "领先 $ahead"
            else
                set state "分叉(落后 $behind / 领先 $ahead)"
            end

            printf '    \033[1;36m→ %s\033[0m   %s   HEAD:%s  %s:%s\n' \
                $remote $state $head_sha $remote $remote_sha
        end
        echo
    end
end
