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
    ~/Documents/script
    ~/Documents/KnowledgeSystem
  )
  for d in $dirs; do
    echo ">>> $d"
    git -C "$d" fetch --all && git -C "$d" pull --rebase
    echo
  done
}
