# git
## 提交git工具
# commit() {
#   git add .
#   git commit -m "$(date "+%Y-%m-%d %H:%M")"
# }
commit() {
  local repo

  # 如果没有参数，使用当前目录
  if [[ -z "$1" ]]; then
    repo="$PWD"
    echo "未指定仓库，将提交当前目录：$repo"
  else
    local -A repos=(
      script /home/zefy/Documents/Script/
      know   /home/zefy/Documents/KnowledgeSystem/
      dotfiles  /home/zefy/.dotfiles
      novel   /home/zefy/Documents/Novel/
    )
    repo="${repos[$1]}"
    if [[ -z "$repo" ]]; then
      echo "错误：未知的仓库别名 '$1'"
      echo "可用别名：${(@k)repos}"
      return 1
    fi
  fi

  cd "$repo" && git add . && git commit -m "$(date "+%Y-%m-%d %H:%M")"
}


push() {
  git add .
  git commit --quiet -m "$(date "+%Y-%m-%d %H:%M")"
  echo
  echo "    \033[1;36m→ gitee\033[0m    $(git push gitee main 2>&1 | tail -1)"
  echo "    \033[1;36m→ github\033[0m   $(git push github main 2>&1 | tail -1)"
}

pushe() {
  git add .
  git commit --quiet -m "$(date "+%Y-%m-%d %H:%M")"
  echo
  echo "    \033[1;36m→ gitee\033[0m    $(git push gitee main 2>&1 | tail -1)"
}

pushb() {
  git add .
  git commit --quiet -m "$(date "+%Y-%m-%d %H:%M")"
  echo
  echo "    \033[1;36m→ github\033[0m   $(git push github main 2>&1 | tail -1)"
}

pullall() {
  local dirs=(
    ~/.dotfiles
    ~/Documents/Script
    ~/Documents/KnowledgeSystem
    ~/Documents/Novel
  )
  for d in $dirs; do
    echo "\033[1;33m  ── $d ──\033[0m"
    echo "    \033[1;36m→ gitee\033[0m    $(git -C "$d" fetch gitee --quiet 2>&1; git -C "$d" pull --rebase gitee main 2>&1 | tail -1)"
    echo
  done
}

pushall() {
  local orig=$(pwd)

  echo "\033[1;33m  ── ~/.dotfiles ──\033[0m"
  cd ~/.dotfiles || return
  push

  echo
  echo "\033[1;33m  ── ~/Documents/Script ──\033[0m"
  cd ~/Documents/Script || return
  pushe

  echo
  echo "\033[1;33m  ── ~/Documents/KnowledgeSystem ──\033[0m"
  cd ~/Documents/KnowledgeSystem || return
  push

  echo
  echo "\033[1;33m  ── ~/Documents/Novel ──\033[0m"
  cd ~/Documents/Novel || return
  pushe

  cd "$orig"
}

commitall() {
  local dirs=(
    ~/.dotfiles
    ~/Documents/Script
    ~/Documents/KnowledgeSystem
    ~/Documents/Novel
  )
  for d in $dirs; do
    echo "\033[1;33m  ── $d ──\033[0m"
    (cd "$d" && git add . && git commit -m "$(date "+%Y-%m-%d %H:%M")")
    echo
  done
}

## 查询各仓库与远程的领先/落后状态(只 fetch,不做任何改动)
# 注意:local 声明必须集中在函数顶部,不能写在循环里。
# zsh 对循环内重复 local 同名变量会向 stdout 打印该变量当前值。
query() {
  local dirs=(
    ~/.dotfiles
    ~/Documents/Script
    ~/Documents/KnowledgeSystem
    ~/Documents/Novel
  )
  local d remotes remote ref behind ahead state head_sha remote_sha

  for d in $dirs; do
    echo "\033[1;33m  ── $d ──\033[0m"
    if ! git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "    不是 git 仓库，跳过"
      echo
      continue
    fi

    remotes=("${(@f)$(git -C "$d" remote)}")
    if [[ -z "$remotes" ]]; then
      echo "    没有配置远程，跳过"
      echo
      continue
    fi

    git -C "$d" fetch --all --quiet 2>&1

    head_sha=$(git -C "$d" rev-parse --short HEAD 2>/dev/null)

    for remote in $remotes; do
      ref="$remote/main"
      if ! git -C "$d" rev-parse --verify --quiet "$ref" >/dev/null 2>&1; then
        echo "    \033[1;36m→ $remote\033[0m   无 $remote/main 分支"
        continue
      fi

      remote_sha=$(git -C "$d" rev-parse --short "$ref" 2>/dev/null)
      behind=$(git -C "$d" rev-list --count HEAD.."$ref" 2>/dev/null)
      ahead=$(git -C "$d" rev-list --count "$ref"..HEAD 2>/dev/null)

      if [[ "$behind" -eq 0 && "$ahead" -eq 0 ]]; then
        state="同步"
      elif [[ "$behind" -gt 0 && "$ahead" -eq 0 ]]; then
        state="落后 $behind"
      elif [[ "$behind" -eq 0 && "$ahead" -gt 0 ]]; then
        state="领先 $ahead"
      else
        state="分叉(落后 $behind / 领先 $ahead)"
      fi
      echo "    \033[1;36m→ $remote\033[0m   $state   HEAD:$head_sha  $remote:$remote_sha"
    done
    echo
  done
}
