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
  echo "\033[1;36m  ━━━  PUSH → gitee  ━━━\033[0m"
  git push gitee main
  echo "\033[1;32m  ━━━  ✓ gitee 完成  ━━━\033[0m"

  echo
  echo "\033[1;36m  ━━━  PUSH → github  ━━━\033[0m"
  git push github main
  echo "\033[1;32m  ━━━  ✓ github 完成  ━━━\033[0m"
}

pushe() {
  git add .
  git commit -m "$(date "+%Y-%m-%d %H:%M")"

  echo
  echo "\033[1;36m  ━━━  PUSH → gitee  ━━━\033[0m"
  git push gitee main
  echo "\033[1;32m  ━━━  ✓ gitee 完成  ━━━\033[0m"
}


pushb() {
  git add .
  git commit -m "$(date "+%Y-%m-%d %H:%M")"

  echo
  echo "\033[1;36m  ━━━  PUSH → github  ━━━\033[0m"
  git push github main
  echo "\033[1;32m  ━━━  ✓ github 完成  ━━━\033[0m"
}


pull() {
  local dirs=(
    ~/.dotfiles
    ~/Documents/Script
    ~/Documents/KnowledgeSystem
  )
  for d in $dirs; do
    echo ">>> $d"
    git -C "$d" fetch gitee && git -C "$d" pull --rebase gitee main
    echo
  done
}


pushall() {
  local orig=$(pwd)

  echo
  echo "\033[1;33m  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  echo "\033[1;33m  仓库: ~/.dotfiles\033[0m"
  echo "\033[1;33m  推送: gitee + github\033[0m"
  echo "\033[1;33m  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  cd ~/.dotfiles || return
  push

  echo
  echo "\033[1;33m  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  echo "\033[1;33m  仓库: ~/Documents/Script\033[0m"
  echo "\033[1;33m  推送: gitee\033[0m"
  echo "\033[1;33m  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  cd ~/Documents/Script || return
  pushe

  echo
  echo "\033[1;33m  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  echo "\033[1;33m  仓库: ~/Documents/KnowledgeSystem\033[0m"
  echo "\033[1;33m  推送: gitee + github\033[0m"
  echo "\033[1;33m  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
  cd ~/Documents/KnowledgeSystem || return
  push

  cd "$orig"
}
