# git
## 提交git工具
# commit() {
#   git add .
#   git commit -m "$(date "+%Y-%m-%d %H:%M")"
# }

commit() {
  local -A repos=(
    script /home/zefy/Documents/Script/
    know   /home/zefy/Documents/KnowledgeSystem/
    dotfiles  /home/zefy/.dotfiles
    novel   /home/zefy/Documents/Novel/
  )

  local repo="${repos[$1]}"
  if [[ -z "$repo" ]]; then
    echo "错误：未知的仓库别名 '$1'"
    echo "可用别名：${(@k)repos}"
    return 1
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
