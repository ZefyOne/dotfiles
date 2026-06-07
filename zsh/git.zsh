# git
## 提交git工具
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





