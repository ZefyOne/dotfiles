# git
## 提交git工具
commit() {
  git add .
  git commit -m "$(date "+%Y-%m-%d %H:%M")"
}

push() {
  git add .
  git commit -m "$(date "+%Y-%m-%d %H:%M")"
  echo
  echo "    \033[1;36m→ gitee\033[0m    $(git push gitee main 2>&1 | tail -1)"
  echo "    \033[1;36m→ github\033[0m   $(git push github main 2>&1 | tail -1)"
}

pushe() {
  git add .
  git commit -m "$(date "+%Y-%m-%d %H:%M")"
  echo
  echo "    \033[1;36m→ gitee\033[0m    $(git push gitee main 2>&1 | tail -1)"
}

pushb() {
  git add .
  git commit -m "$(date "+%Y-%m-%d %H:%M")"
  echo
  echo "    \033[1;36m→ github\033[0m   $(git push github main 2>&1 | tail -1)"
}

pullall() {
  local dirs=(
    ~/.dotfiles
    ~/Documents/Script
    ~/Documents/KnowledgeSystem
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

  cd "$orig"
}
