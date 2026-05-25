# Git 操作速查

## 目录

- [基础操作](#基础操作)
- [分支管理](#分支管理)
- [远程操作](#远程操作)
- [查看历史](#查看历史)
- [撤销与回退](#撤销与回退)
- [暂存与工作区](#暂存与工作区)
- [合并与变基](#合并与变基)
- [Stash](#stash)
- [标签](#标签)
- [子模块](#子模块)
- [高级技巧](#高级技巧)

---

## 基础操作

```bash
# 初始化仓库
git init

# 克隆仓库
git clone <url>
git clone <url> <目录名>
git clone --depth 1 <url>                    # 浅克隆，只拉最新 commit
git clone --recurse-submodules <url>         # 同时克隆子模块

# 添加文件到暂存区
git add <文件>
git add .                                    # 添加所有变更
git add -p                                   # 交互式分段添加

# 提交
git commit -m "消息"
git commit -am "消息"                         # 跳过 git add，直接提交已跟踪文件的变更
git commit --amend                           # 修改上一次提交（未 push 时用）
git commit --amend --no-edit                 # 不改消息，把当前变更合入上次提交
git commit --allow-empty                     # 允许空提交

# 查看状态
git status
git status -s                                # 简短格式
```

## 分支管理

```bash
# 查看分支
git branch                                   # 本地分支
git branch -r                                # 远程分支
git branch -a                                # 所有分支
git branch -v                                # 分支 + 最新提交

# 创建分支
git branch <分支名>
git checkout -b <分支名>                      # 创建并切换
git switch -c <分支名>                        # 新版 git 创建并切换

# 切换分支
git checkout <分支名>
git switch <分支名>                           # 新版 git

# 删除分支
git branch -d <分支名>                        # 已合并的分支
git branch -D <分支名>                        # 强制删除（未合并）

# 删除远程分支
git push origin --delete <分支名>

# 重命名分支
git branch -m <旧名> <新名>

# 查看分支合并情况
git branch --merged                           # 已合并到当前分支的
git branch --no-merged                        # 未合并的
```

## 远程操作

```bash
# 管理远程仓库
git remote -v                                 # 查看远程
git remote add <别名> <url>                   # 添加远程
git remote remove <别名>                      # 删除远程
git remote rename <旧名> <新名>               # 重命名

# 拉取
git pull                                      # = git fetch + git merge
git pull --rebase                             # = git fetch + git rebase（更干净的线）
git pull --autostash                          # 自动 stash 本地修改后拉取

# 推送
git push                                      # 推送到默认远程
git push -u <远程> <分支>                      # 推送并建立上游关联
git push --force                              # 强制推送（危险！）
git push --force-with-lease                   # 比 --force 安全，会检查远程是否被更新过
git push --tags                               # 推送标签

# 获取远程信息
git fetch                                     # 拉取远程但不合并
git fetch --prune                             # 拉取同时删除本地已不存在的远程分支引用
git fetch -p                                  # 同上，简写
```

## 查看历史

```bash
# 基础日志
git log
git log --oneline                             # 一行显示
git log --graph --oneline --decorate --all    # 漂亮的 DAG 图（最常用）

# 格式化日志
git log --pretty=format:"%h %an %ar %s"
  # %h   短 hash
  # %an  作者名
  # %ar  相对时间
  # %s   提交消息
  # %d   引用名（分支、标签）

# 筛选日志
git log --author="<名字>"                     # 按作者
git log --since="2024-01-01"                  # 按时间
git log --until="2024-12-31"
git log --grep="<关键字>"                      # 按提交消息
git log -S "<字符串>"                          # 按代码变更内容（pickaxe）
git log -p                                    # 显示 diff
git log --stat                                # 显示文件变更统计

# 查看单个提交
git show <commit-hash>
git show HEAD
git show HEAD~1                               # 父提交

# 查看文件的变更历史
git log --follow -- <文件>                     # 跟踪文件重命名
git blame <文件>                               # 文件每一行是谁改的
```

## 撤销与回退

```bash
# 工作区（未暂存）
git restore <文件>                             # 丢弃工作区的修改
git checkout -- <文件>                         # 旧版写法

# 暂存区
git restore --staged <文件>                    # 取消暂存（保留工作区修改）
git reset HEAD <文件>                          # 旧版写法

# 回退提交
git reset --soft HEAD~1                       # 撤销提交，改动留在暂存区
git reset --mixed HEAD~1                      # 撤销提交，改动留在工作区（默认）
git reset --hard HEAD~1                       # 撤销提交，改动全部丢弃（危险！）
git reset --hard <commit-hash>                # 回退到指定版本

# 回退到远程状态
git reset --hard origin/main

# revert（安全地撤销历史提交）
git revert HEAD                               # 产生一个反向提交
git revert <commit-hash>

# 恢复已删除的分支（通过 reflog）
git reflog                                    # 找到丢失的 commit
git checkout -b <分支> <commit-hash>
```

## 暂存与工作区

```bash
# 查看差异
git diff                                      # 工作区 vs 暂存区
git diff --staged                             # 暂存区 vs 上次提交（cached）
git diff <分支1> <分支2>                       # 两个分支对比
git diff <commit1> <commit2>                  # 两个提交对比
git diff <commit> -- <文件>                    # 特定文件的变更

# 忽略文件权限
git config core.fileMode false

# 从跟踪中移除（保留本地文件）
git rm --cached <文件>

# 移动/重命名
git mv <旧路径> <新路径>
```

## 合并与变基

```bash
# 合并
git merge <分支名>                            # 将分支合并到当前分支
git merge --no-ff <分支名>                    # 禁止快进，保留分支历史
git merge --squash <分支名>                   # 压缩合并，不保留分支历史
git merge --abort                             # 中止合并（冲突时）
git merge --continue                          # 继续合并（解决冲突后）

# 变基
git rebase <分支>                              # 将当前分支变基到目标分支
git rebase -i HEAD~3                          # 交互式变基，操作最近 3 个提交
git rebase --abort                            # 中止变基
git rebase --continue                         # 继续变基（解决冲突后）
git rebase --skip                             # 跳过当前提交

# 交互式变基选项
  pick    # 保留该提交
  reword  # 保留内容，修改提交消息
  edit    # 保留提交，停下来修改
  squash  # 合并到上一个提交
  fixup   # 合并到上一个提交，丢弃消息
  drop    # 删除该提交

# cherry-pick：挑选提交到当前分支
git cherry-pick <commit-hash>
git cherry-pick <hash1> <hash2>               # 多个提交
git cherry-pick <hash>..<hash>                # 范围
```

## Stash

```bash
# 基础使用
git stash                                     # 暂存当前改动
git stash push -m "描述"                      # 带描述的暂存
git stash pop                                 # 恢复并删除最新的 stash
git stash apply                               # 恢复但不删除
git stash list                                # 查看所有 stash
git stash drop stash@{0}                      # 删除指定 stash
git stash clear                               # 清空所有 stash

# 高级
git stash -u                                  # 同时暂存未跟踪文件
git stash -a                                  # 同时暂存忽略的文件
git stash push --patch                        # 交互式选择要暂存的内容
git stash branch <分支名>                      # 从 stash 创建新分支
git stash show -p stash@{0}                   # 查看 stash 的具体 diff
```

## 标签

```bash
# 创建标签
git tag <标签名>                               # 轻量标签
git tag -a <标签名> -m "说明"                  # 附注标签
git tag -a <标签名> <commit-hash> -m "说明"    # 给历史提交打标签

# 查看标签
git tag                                       # 列出标签
git tag -l "v2.*"                             # 筛选
git show <标签名>                              # 查看标签信息

# 推送标签
git push origin <标签名>
git push --tags                               # 推送所有本地标签

# 删除标签
git tag -d <标签名>                            # 本地
git push origin --delete <标签名>              # 远程
```

## 子模块

```bash
# 添加子模块
git submodule add <url> <路径>

# 初始化子模块
git submodule init
git submodule update                          # 拉取子模块到正确版本
git submodule update --init --recursive       # 初始化 + 更新 + 嵌套

# 克隆含子模块的仓库
git clone --recurse-submodules <url>

# 更新子模块
git submodule update --remote                 # 更新到子模块的最新版本

# 在子模块中操作
cd <子模块路径>
git fetch && git merge origin/main
cd ..
git add <子模块路径>
git commit -m "更新子模块"

# 查看子模块状态
git submodule status
git submodule foreach git status              # 在所有子模块中执行命令

# 删除子模块（比较繁琐）
git submodule deinit <路径>
git rm <路径>
rm -rf .git/modules/<路径>
```

## 高级技巧

### Reflog（最后的安全网）

即使 `git reset --hard` 或者删了分支，reflog 也能救命。

```bash
git reflog                                    # 查看 HEAD 的所有历史移动
git reflog show <分支名>                       # 查看某个分支的历史
git reset --hard HEAD@{2}                     # 回到 reflog 中的位置
```

### Bisect（二分查找 bug 来源）

```bash
git bisect start                              # 开始
git bisect bad                                # 当前版本有 bug
git bisect good <已知正常版本>                  # 标记一个正常版本
# git 会切换到中间提交，测试后标记：
git bisect good                               # 这个提交正常
git bisect bad                                # 这个提交有问题
# 重复直到找到第一个有 bug 的提交
git bisect reset                              # 结束 bisect
# 自动化：
git bisect start HEAD v1.0 && git bisect run npm test
```

### Worktree（并行工作）

在一个仓库目录外检出另一个分支，互不干扰。

```bash
git worktree add ../hotfix hotfix-branch      # 在外部目录检出分支
git worktree list                             # 查看所有 worktree
git worktree remove ../hotfix                 # 移除
git worktree prune                            # 清理过期引用
```

### 修改历史（谨慎使用）

```bash
# 修改最近一条提交的消息
git commit --amend -m "新消息"

# 修改历史多个提交的消息
git rebase -i HEAD~5
# 把要改的提交前的 pick 改为 reword

# 合并多个提交
git rebase -i HEAD~5
# 把除了第一个以外的 pick 改为 squash 或 fixup

# 拆分提交
git rebase -i HEAD~5
# 把要拆分的提交前标记为 edit
# 然后 git reset HEAD^，再分批 add 和 commit
# 最后 git rebase --continue
```

### 清理

```bash
# 清理未跟踪文件
git clean -n                                  # 预览（dry run）
git clean -f                                  # 删除未跟踪文件
git clean -fd                                 # 删除未跟踪文件和目录
git clean -fdX                                # 删除被 gitignore 的文件

# 压缩仓库
git gc                                        # 垃圾回收
git gc --aggressive                           # 深度压缩
git repack -a -d --depth=250 --window=250     # 更彻底的压缩
```

### 配置别名

```bash
# 常用别名
git config --global alias.lg "log --graph --oneline --decorate --all"
git config --global alias.ci "commit"
git config --global alias.co "checkout"
git config --global alias.br "branch"
git config --global alias.st "status"
git config --global alias.unstage "reset HEAD --"
git config --global alias.last "log -1 HEAD"
git config --global alias.visual "!gitk"

# 使用：git lg 替代 git log --graph --oneline --decorate --all
```

### 稀疏检出

只检出仓库的部分文件，适合大型 monorepo。

```bash
git clone --filter=blob:none <url>           # 不下载大文件 blob
git sparse-checkout init --cone               # 开启稀疏检出
git sparse-checkout set <目录1> <目录2>       # 只检出的目录
```

### 查找

```bash
# 按提交内容查找
git log -S "函数名" --source --all

# 按字符串查找（所有分支）
git grep "<关键字>" $(git rev-list --all)

# 按文件内容搜索
git grep "TODO\|FIXME"                        # 搜索当前工作区
git grep "TODO" $(git rev-list --all) -- src/ # 搜索历史

# 查找谁改了一行代码
git blame -L 10,20 <文件>                     # 查看第 10-20 行
git blame -C -C -C <文件>                     # 跟踪跨文件移动的代码
```

### Hook（钩子）

`.git/hooks/` 下的脚本，在特定 git 事件触发。

```bash
# 可用钩子
pre-commit       # commit 前运行（lint、格式化）
pre-push         # push 前运行（测试）
post-commit      # commit 后运行（通知）
prepare-commit-msg  # 准备提交消息时
post-merge       # merge 后运行
```

使用 `git init` 生成的模板钩子在 `.git/hooks/` 下，后缀 `.sample`。移除后缀启用。

### 其他实用操作

```bash
# 暂存并合并
git checkout --ours <文件>                    # 合并冲突时，保留当前分支版本
git checkout --theirs <文件>                  # 合并冲突时，保留对方版本

# log 所有涉及某个文件的提交
git log --all --full-history -- <文件>

# 比较两个分支的文件列表
git diff --name-status <分支1>..<分支2>

# 查看某个文件在特定提交中的内容
git show <commit>:<路径>

# 创建一个空提交
git commit --allow-empty -m "初始提交"

# 创建 orphan 分支（无父提交的独立分支）
git checkout --orphan <分支名>

# 签名提交
git commit -S -m "消息"                       # 需要配置 GPG 密钥

# 维护 .gitignore 生效性
git check-ignore -v <文件>                    # 检查文件被哪条 gitignore 规则忽略

# 只提交文件的部分变更（交互式）
git add -p
```

### .gitattributes

控制 git 如何处理特定文件。

```gitattributes
# 统一换行符
* text=auto
*.sh text eol=lf
*.bat text eol=crlf

# 标记二进制文件
*.png binary
*.jpg binary

# diff 配置
*.ipynb diff=jupyternotebook

# 合并策略
*.lock -text merge=union
```

## 工作流速查表

| 场景 | 命令 |
|------|------|
| 刚开始新功能 | `git checkout -b feat/xxx main` |
| 保存当前进度 | `git stash push -m "进度"` |
| 拉取最新代码 | `git pull --rebase` |
| 合并功能分支 | `git merge --no-ff feat/xxx` |
| 撤销本地修改 | `git restore <文件>` |
| 回退已提交的 | `git revert HEAD` |
| 搞砸了想恢复 | `git reflog` 找到 commit 然后 `git reset --hard` |
| 修复小问题 | `git commit -a --fixup HEAD` + `git rebase -i --autosquash HEAD~3` |
