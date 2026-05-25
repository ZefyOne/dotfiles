#!/bin/bash

# ========== 仓库列表（填入本地绝对路径）==========
REPOS=(
  "$HOME/.dotfiles"
  "$HOME/Documents/script"
)
# ================================================

# 远程仓库配置（根据每个仓库自行配置）
declare -A GITHUB_URLS
declare -A GITEE_URLS

# 在这里为每个仓库配置远程地址
GITHUB_URLS["$HOME/.dotfiles"]="git@github.com:zefyone/dotfiles.git"
GITEE_URLS["$HOME/.dotfiles"]="git@gitee.com:zefyone/dotfiles.git"

# script仓库只推送Gitee
GITEE_URLS["$HOME/Documents/script"]="git@gitee.com:zefyone/script.git"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

push_single_repo() {
  local repo_path=$1

  if [ -z "$repo_path" ]; then
    return
  fi

  if [ ! -d "$repo_path" ]; then
    log_error "仓库不存在: $repo_path"
    return 1
  fi

  if [ ! -d "$repo_path/.git" ]; then
    log_error "不是Git仓库: $repo_path"
    return 1
  fi

  echo ""
  echo "========================================"
  log_info "处理仓库: $repo_path"
  echo "========================================"

  cd "$repo_path" || return 1

  # 获取当前分支
  current_branch=$(git branch --show-current)
  log_info "当前分支: $current_branch"

  # 自动提交
  log_info "执行 git add . && git commit -m '更新' ..."
  git add .
  commit_result=$(git commit -m "更新" 2>&1)
  commit_exit=$?

  if [ $commit_exit -ne 0 ]; then
    if echo "$commit_result" | grep -q "nothing to commit"; then
      log_info "没有需要提交的更改"
    else
      log_error "提交失败: $commit_result"
      return 1
    fi
  else
    log_info "提交成功"
  fi

  # 获取远程仓库
  github_url="${GITHUB_URLS[$repo_path]}"
  gitee_url="${GITEE_URLS[$repo_path]}"

  github_result="失败"
  gitee_result="失败"
  github_msg=""
  gitee_msg=""
  github_exit_code=""
  gitee_exit_code=""

  # 推送到 GitHub（使用 github 作为远程名）
  if [ -n "$github_url" ]; then
    # 检查并添加 github 远程仓库
    if ! git remote get-url github &>/dev/null; then
      log_info "添加 GitHub 远程仓库..."
      git remote add github "$github_url"
    fi

    log_info "推送到 GitHub (main 分支)..."
    push_gh=$(git push github main 2>&1)
    github_exit_code=$?

    if [ $github_exit_code -eq 0 ]; then
      github_result="成功"
      log_info "GitHub 推送成功"
    else
      github_msg="$push_gh"
      log_error "GitHub 推送失败 (退出码: $github_exit_code)"
      log_error "失败详情: $push_gh"
    fi
  else
    log_warn "未配置 GitHub 远程地址，跳过 GitHub 推送"
  fi

  # 推送到 Gitee（使用 gitee 作为远程名）
  if [ -n "$gitee_url" ]; then
    # 检查并添加 gitee 远程仓库
    if ! git remote get-url gitee &>/dev/null; then
      log_info "添加 Gitee 远程仓库..."
      git remote add gitee "$gitee_url"
    fi

    log_info "推送到 Gitee (main 分支)..."
    push_gitee=$(git push gitee main 2>&1)
    gitee_exit_code=$?

    if [ $gitee_exit_code -eq 0 ]; then
      gitee_result="成功"
      log_info "Gitee 推送成功"
    else
      gitee_msg="$push_gitee"
      log_error "Gitee 推送失败 (退出码: $gitee_exit_code)"
      log_error "失败详情: $push_gitee"
    fi
  else
    log_warn "未配置 Gitee 远程地址，跳过 Gitee 推送"
  fi

  # 写入详细的结果文件
  result_file="$repo_path/push_result.txt"
  {
    echo "========================================="
    echo "仓库: $repo_path"
    echo "分支: main"
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================="
    echo ""
    echo "--- GitHub 推送状态 ---"
    echo "状态: $github_result"
    if [ -n "$github_exit_code" ]; then
      echo "退出码: $github_exit_code"
    fi
    if [ -n "$github_msg" ]; then
      echo "错误详情:"
      echo "$github_msg"
      echo ""
    fi
    echo ""
    echo "--- Gitee 推送状态 ---"
    echo "状态: $gitee_result"
    if [ -n "$gitee_exit_code" ]; then
      echo "退出码: $gitee_exit_code"
    fi
    if [ -n "$gitee_msg" ]; then
      echo "错误详情:"
      echo "$gitee_msg"
      echo ""
    fi
    echo "========================================="
  } >"$result_file"

  log_info "详细结果已写入: $result_file"

  # 如果有失败，返回非0
  if [ "$github_result" = "失败" ] && [ -n "$github_url" ]; then
    return 1
  fi
  if [ "$gitee_result" = "失败" ] && [ -n "$gitee_url" ]; then
    return 1
  fi

  return 0
}

main() {
  echo "========================================"
  echo "  GitHub & Gitee 批量推送脚本"
  echo "========================================"
  echo "推送目标分支: main"
  echo "远程仓库: github, gitee"
  echo "========================================"
  echo ""

  failed_repos=()

  for repo in "${REPOS[@]}"; do
    if ! push_single_repo "$repo"; then
      failed_repos+=("$repo")
    fi
  done

  echo ""
  echo "========================================"
  if [ ${#failed_repos[@]} -eq 0 ]; then
    log_info "全部完成 ✓"
  else
    log_error "以下仓库推送失败:"
    for repo in "${failed_repos[@]}"; do
      echo "  - $repo"
      echo "    查看详情: $repo/push_result.txt"
    done
  fi
  echo "========================================"

  # 返回失败数量作为退出码
  exit ${#failed_repos[@]}
}

main "$@"
