# git
## 提交git工具
commit() {
  git add .
  git commit -m "$(date "+%Y-%m-%d %H:%M")"
}

push() {
  git add .
  git commit -m "$(date "+%Y-%m-%d %H:%M")"
  git push gitee main
  git push github main
}

pushe() {
  git add .
  git commit -m "$(date "+%Y-%m-%d %H:%M")"
  git push gitee main
}


pushb() {
  git add .
  git commit -m "$(date "+%Y-%m-%d %H:%M")"
  git push github main
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

  echo ">>> ~/.dotfiles → gitee + github"
  cd ~/.dotfiles || return
  push

  echo ">>> ~/Documents/Script → gitee"
  cd ~/Documents/Script || return
  pushe

  echo ">>> ~/Documents/KnowledgeSystem → gitee + github"
  cd ~/Documents/KnowledgeSystem || return
  push

  cd "$orig"
}
