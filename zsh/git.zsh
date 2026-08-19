# git
## 提交git工具

# ===== 仓库配置(全局唯一,下面所有命令遍历这里) =====
# 格式:别名  路径  远程标记(gitee / github / gitee github)
# 增删仓库只需改这一处;某仓库新增远程只改该行第三个标记。
typeset -ga repos=(
  dotfiles  "$HOME/.dotfiles"                  "gitee github"
  script    "$HOME/Documents/Script"           "gitee"
  know      "$HOME/Documents/KnowledgeSystem"  "gitee github"
  novel     "$HOME/Documents/Novel"            "gitee"
)

# 按别名查路径 / 远程标记(找不到返回 1)
repo_path() {
  local i
  for ((i = 1; i <= ${#repos}; i += 3)); do
    [[ ${repos[$i]} == "$1" ]] && { print -r -- "${repos[$i + 1]}"; return 0 }
  done
  return 1
}

repo_remotes() {
  local i
  for ((i = 1; i <= ${#repos}; i += 3)); do
    [[ ${repos[$i]} == "$1" ]] && { print -r -- "${repos[$i + 2]}"; return 0 }
  done
  return 1
}

commit() {
  local repo i
  local -a names

  # 如果没有参数，使用当前目录
  if [[ -z "$1" ]]; then
    repo="$PWD"
    echo "未指定仓库，将提交当前目录：$repo"
  else
    repo=$(repo_path "$1")
    if [[ -z "$repo" ]]; then
      for ((i = 1; i <= ${#repos}; i += 3)); do
        names+=("${repos[$i]}")
      done
      echo "错误：未知的仓库别名 '$1'"
      echo "可用别名：${(j: :)names}"
      return 1
    fi
  fi

  cd "$repo" && git add . && git commit -m "$(date "+%Y-%m-%d %H:%M")"
}

# 提交并推当前目录仓库到指定的一个或多个远程(参数为远程名)
push() {
  git add .
  git commit --quiet -m "$(date "+%Y-%m-%d %H:%M")"
  echo
  local r
  for r in "$@"; do
    echo "    \033[1;36m→ $r\033[0m   $(git push "$r" main 2>&1 | tail -1)"
  done
}

pushe() { push gitee }
pushb() { push github }

pushall() {
  local i dir remotes
  for ((i = 1; i <= ${#repos}; i += 3)); do
    dir=${repos[$i + 1]}
    remotes=${repos[$i + 2]}
    echo "\033[1;33m  ── $dir ──\033[0m"
    (cd "$dir" && push $=remotes)
    echo
  done
}

pullall() {
  local i dir
  for ((i = 1; i <= ${#repos}; i += 3)); do
    dir=${repos[$i + 1]}
    echo "\033[1;33m  ── $dir ──\033[0m"
    echo "    \033[1;36m→ gitee\033[0m   $(git -C "$dir" fetch gitee --quiet 2>&1; git -C "$dir" pull --rebase gitee main 2>&1 | tail -1)"
    echo
  done
}

commitall() {
  local i dir
  for ((i = 1; i <= ${#repos}; i += 3)); do
    dir=${repos[$i + 1]}
    echo "\033[1;33m  ── $dir ──\033[0m"
    (cd "$dir" && git add . && git commit -m "$(date "+%Y-%m-%d %H:%M")")
    echo
  done
}

## 查询各仓库与远程的领先/落后状态(只 fetch,不做任何改动)
# 注意:local 声明必须集中在函数顶部,不能写在循环里。
# zsh 对循环内重复 local 同名变量会向 stdout 打印该变量当前值。
# 另:变量名不要用 path / cdpath 等 zsh 特殊数组(与 PATH 绑定)。
query() {
  local i dir remotes remote ref behind ahead state head_sha remote_sha

  for ((i = 1; i <= ${#repos}; i += 3)); do
    dir=${repos[$i + 1]}
    remotes=${repos[$i + 2]}
    echo "\033[1;33m  ── $dir ──\033[0m"
    if ! git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "    不是 git 仓库，跳过"
      echo
      continue
    fi

    if [[ -z "$remotes" ]]; then
      echo "    未配置远程，跳过"
      echo
      continue
    fi

    git -C "$dir" fetch --all --quiet 2>&1

    head_sha=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)

    for remote in $=remotes; do
      ref="$remote/main"
      if ! git -C "$dir" rev-parse --verify --quiet "$ref" >/dev/null 2>&1; then
        echo "    \033[1;36m→ $remote\033[0m   无 $remote/main 分支"
        continue
      fi

      remote_sha=$(git -C "$dir" rev-parse --short "$ref" 2>/dev/null)
      behind=$(git -C "$dir" rev-list --count HEAD.."$ref" 2>/dev/null)
      ahead=$(git -C "$dir" rev-list --count "$ref"..HEAD 2>/dev/null)

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
