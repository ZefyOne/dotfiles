# Git 实现原理

## 目录

1. [核心数据结构：内容寻址文件系统](#1-核心数据结构内容寻址文件系统)
2. [Git 对象模型](#2-git-对象模型)
3. [.git 目录结构](#3-git-目录结构)
4. [引用与符号引用](#4-引用与符号引用)
5. [包文件与压缩](#5-包文件与压缩)
6. [索引文件](#6-索引文件)
7. [三棵树架构](#7-三棵树架构)
8. [合并机制](#8-合并机制)
9. [传输协议](#9-传输协议)
10. [垃圾回收](#10-垃圾回收)

---

## 1. 核心数据结构：内容寻址文件系统

Git 本质上是一个**内容寻址的文件系统**，其核心是一个键值存储（key-value store）。

### 1.1 寻址方式

Git 使用 SHA-1 哈希值作为内容的地址。对于任意内容，Git 计算其 SHA-1 哈希，然后将内容存储在以该哈希值为文件名的文件中。

```
content -> SHA-1(content) -> 40位十六进制字符串 -> 存储路径
```

SHA-1 输出 160 bit（20 bytes），用 40 位十六进制表示。存储时取前 2 位作为目录名、后 38 位作为文件名，以避免单个目录文件过多。

```
存储路径: .git/objects/ab/cdef1234567890abcdef1234567890abcdef12
                                ^^ ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                            目录名                       文件名
```

### 1.2 存储格式

每个对象在存储前经历两个步骤：

1. **构造对象头**：`<type> <content_length>\0<content>`
2. **使用 zlib deflate 压缩**

```c
// 伪代码
char *header = "<type> <content_length>";
char *store = strconcat(header, "\0", content);
char *compressed = zlib_deflate(store);
write_file(".git/objects/XX/YYYYYY", compressed);
```

### 1.3 寻址验证：为什么 Git 被认为是安全的

- 内容是地址的**唯一决定因素**：给定内容，其地址是确定的
- 修改内容必然改变地址：无法篡改内容而不被检测到
- 标签（tag）可以 GPG 签名：从可信根开始构建信任链
- SHA-1 碰撞的防御：从 2.13 版本开始 Git 内置了检测 SHA-1 碰撞的机制（检测两个不同对象具有相同哈希的情况）

### 1.4 解包验证

```bash
# 查看原始压缩内容
openssl zlib -d < .git/objects/XX/YYYYYY
# 查看对象类型和内容
git cat-file -p <hash>
```

---

## 2. Git 对象模型

Git 有四种对象类型：**blob**、**tree**、**commit**、**tag**。所有对象都使用上述的内容寻址方式存储。

### 2.1 Blob 对象

Blob（Binary Large Object）存储文件内容。

- 存储的是文件的**内容**，不是文件名或元数据
- 文件名由 tree 对象记录
- 相同的文件内容只会存储一个 blob（因为相同内容产生相同哈希）

```
格式: "blob <content_length>\0<file_content>"
```

```c
// 创建一个 blob 的伪代码
FILE *f = fopen("main.c", "r");
char *content = fread_all(f);
char *store = strconcat("blob ", itoa(strlen(content)), "\0", content);
char *hash = sha1(store);
char *compressed = zlib_deflate(store);
write_file(".git/objects/" + hash[0..1] + "/" + hash[2..], compressed);
fclose(f);
```

### 2.2 Tree 对象

Tree 对象存储目录结构：文件名、文件权限与对应的 blob（或子 tree）哈希的映射。

```
格式: "tree <content_length>\0<entries>"

每个 entry:
  [mode] [filename]\0[SHA-1 的原始二进制 20 bytes]
```

mode 取值：
- `100644` — 普通文件
- `100755` — 可执行文件
- `040000` — 子目录（注意：低版本中为 0040000）
- `120000` — 符号链接
- `160000` — gitlink（子模块）

```
tree 对象的二进制内容（十六进制视图）:
100644 main.c\0<20 bytes SHA-1>
100755 script.sh\0<20 bytes SHA-1>
040000 src\0<20 bytes SHA-1>
```

**关键设计点**：
- Tree 对象按名称排序（字节序），保证同一目录结构的 tree 哈希值相同
- 子目录也存储为 tree 对象，形成递归结构
- 如果两个目录包含完全相同的文件和内容，它们共享同一个 tree 对象哈希

### 2.3 Commit 对象

Commit 对象是对一次提交的快照记录，指向一个 tree 对象，并记录父 commit、作者、提交者信息。

```
格式: "commit <content_length>\0<content>"

内容:
tree <tree_hash>
parent <parent_commit_hash>   // 第一个父 commit
parent <parent_commit_hash>   // 第二个父 commit（合并提交）
author <name> <<email>> <timestamp> <timezone>
committer <name> <<email>> <timestamp> <timezone>

<commit message>
```

```
实际示例:
tree 29ff16c9c14e7652b4f4b8a1b4c1f7c5c7a5d3e1
parent 5b10d2c5d4e3f2a1b6c7d8e9f0a1b2c3d4e5f6
author Alice <alice@example.com> 1713456789 +0800
committer Alice <alice@example.com> 1713456789 +0800

Initial commit
```

**关键设计点**：
- Commit 对象不直接包含差异（diff），只包含完整的 tree 哈希
- 历史是通过 `parent` 字段形成的链表/有向无环图（DAG）
- 合并提交有多个 parent
- 时间戳是 Unix 时间戳 + 时区，仅用于信息展示，不影响 commit 的哈希值
- 作者（author）和提交者（committer）可以不同（如变基或补丁应用时）

### 2.4 Tag 对象

Tag 对象（annotated tag）绑定一个名字到一个特定的 commit（或任意对象）。

```
格式: "tag <content_length>\0<content>"

内容:
object <commit_hash>
type commit
tag v1.0.0
tagger <name> <<email>> <timestamp> <timezone>

<tag message>
```

轻量标签（lightweight tag）只是一个引用（见下文），不创建 tag 对象。

### 2.5 对象之间的关系

```
                  ┌───────────────────┐
                  │  Commit (abc123)   │
                  │  tree: def456      │
                  │  parent: 789abc    │
                  │  author: Alice     │
                  │  message: "..."    │
                  └────────┬──────────┘
                           │ points to
                           ▼
                  ┌───────────────────┐
                  │  Tree (def456)     │
                  │  blob 100644 a.c  │──────▶ Blob (aaa111): "int main() {}"
                  │  blob 100755 b.sh │──────▶ Blob (bbb222): "#!/bin/bash"
                  │  tree 040000 src/ │──────▶ Tree (ccc333): ...
                  └───────────────────┘
```

---

## 3. .git 目录结构

```
.git/
├── HEAD                    # 当前分支指针
├── config                  # 仓库配置
├── description             # 仓库描述（用于 GitWeb）
├── index                   # 暂存区（待提交文件清单）
├── info/
│   ├── exclude             # 本地排除规则（类似 .gitignore 但不上传）
│   └── refs/               # 引用打包后，未打包的引用信息
├── objects/                # 对象数据库
│   ├── info/
│   │   └── packs           # 包索引文件列表
│   ├── pack/
│   │   ├── pack-<hash>.idx # 包文件索引（快速查找）
│   │   └── pack-<hash>.pack# 包文件（多个对象的压缩集合）
│   ├── ab/                 # 散落的松散对象（未打包）
│   │   └── <38-char-hash>
│   └── .../
├── refs/                   # 引用（references）
│   ├── heads/
│   │   ├── main            # 分支 main 指向的 commit hash
│   │   └── feature         # 分支 feature 指向的 commit hash
│   ├── tags/
│   │   └── v1.0            # 标签指向的 commit hash
│   └── remotes/
│       └── origin/
│           └── main        # 远程跟踪分支
├── logs/                   # 引用日志（reflog）
│   ├── HEAD
│   └── refs/
│       ├── heads/
│       │   └── main
│       └── ...
├── objects/info/
│   └── alternates          # 备用对象存储路径
├── FETCH_HEAD              # 最近 fetch 的信息
├── MERGE_HEAD              # 合并中正在合并的 commit
├── MERGE_MSG               # 合并中的提交信息
├── ORIG_HEAD               # 危险操作前的 HEAD 备份
├── CHERRY_PICK_HEAD        # cherry-pick 进行中的引用
├── REBASE_HEAD             # rebase 进行中的引用
├── rebase-merge/           # rebase 临时目录（交互式 rebase）
├── rebase-apply/           # rebase 临时目录（非交互式 rebase）
├── BISECT_LOG              # bisect 日志
├── packed-refs             # 打包后的引用文件
└── hooks/                  # 钩子脚本
    ├── pre-commit
    ├── post-commit
    ├── pre-push
    └── ...
```

### 3.1 HEAD 文件

HEAD 文件指示当前检出的分支或 commit。

典型内容（在分支上）：
```
ref: refs/heads/main
```

分离头指针状态（detached HEAD）：
```
a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0
```

### 3.2 Config 文件

INI 风格，支持分层和包含：

```ini
[core]
    repositoryformatversion = 0
    filemode = true
    bare = false
    logallrefupdates = true
[remote "origin"]
    url = https://github.com/user/repo.git
    fetch = +refs/heads/*:refs/remotes/origin/*
[branch "main"]
    remote = origin
    merge = refs/heads/main
```

---

## 4. 引用与符号引用

引用（reference 或 ref）是指向 commit 或其他对象的指针。Git 将引用作为文件存储，文件内容为目标对象的 SHA-1 哈希。

### 4.1 引用分类

```
refs/
├── heads/       # 本地分支（指向 commit）
├── remotes/     # 远程跟踪分支
├── tags/        # 标签（指向 commit 或 tag 对象）
└── ...          # 特殊用途引用
```

### 4.2 引用文件内容

```
# .git/refs/heads/main
a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0
```
文件内容就是一个 40 字符的 SHA-1 哈希 + 换行符。

### 4.3 符号引用（Symbolic Reference）

符号引用指向另一个引用，而非直接指向对象。

```
HEAD -> refs/heads/main -> a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0
```

HEAD 文件的内容 `ref: refs/heads/main` 就是符号引用的实现。

### 4.4 引用打包（packed-refs）

当引用数量过多时，Git 将所有引用打包到一个文件中以减少磁盘 I/O。

```
# .git/packed-refs
# pack-refs with: peeled fully-peeled sorted
a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0 refs/heads/main
b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b01 refs/heads/feature
^c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b012  # peeled tag（标签指向的 commit）
d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0123 refs/tags/v1.0
```

`^` 行是 peeled tag 信息：表示前一个 tag 对象最终指向的 commit 哈希，避免递归解引用。

Git 查找引用时的读取顺序：

1. 检查 `.git/refs/` 下的单独文件
2. 如果未找到，检查 `.git/packed-refs`

写入永远写入 `.git/refs/` 下的单独文件（不会自动更新 packed-refs）。

---

## 5. 包文件与压缩

松散对象使用 zlib 压缩，效率较低。当对象数量增多时，Git 将多个对象打包成包文件（packfile）以实现更高效的压缩。

### 5.1 何时打包

- `git gc` 或 `git repack` 显式触发
- 松散对象数量超过配置阈值（`gc.auto`，默认 6700）
- `git push` 远程操作时自动打包

### 5.2 包文件格式（.pack）

```
Pack file 结构:
[头部] [对象 1] [对象 2] ... [对象 N] [尾部]

头部 (12 bytes):
  - 4 bytes: 魔数 "PACK"
  - 4 bytes: 版本号 (2 或 3)
  - 4 bytes: 对象数量

每个对象:
  - 类型 + 长度（变长编码 varint）
  - 压缩数据（zlib deflate）或 增量数据

类型:
  0b001 — commit
  0b010 — tree
  0b011 — blob
  0b100 — tag
  0b110 — OFS_DELTA（偏移量增量）
  0b111 — REF_DELTA（引用增量）

尾部 (20 bytes):
  - 所有对象 SHA-1 的校验和
```

### 5.3 增量压缩（Delta Compression）

Git 的核心压缩策略：找到相似对象，只存储差异，而非完整内容。

```
OFS_DELTA:
  [类型标志 0b110] [base object 的相对偏移量（变长编码）] [zlib 压缩的差异数据]

REF_DELTA:
  [类型标志 0b111] [base object 的 20 bytes SHA-1] [zlib 压缩的差异数据]
```

**增量指令集**：
差异数据由一系列指令组成，每条指令要么复制源数据，要么插入新数据：

```
复制指令（高位为 1）:
  1 <4 bytes offset> <3 bytes size>
  含义：从 base 对象的 offset 处复制 size 字节

插入指令（高位为 0）:
  0 <size> <data>
  含义：直接插入 size 字节的新数据
```

**增量压缩算法**（相似哈希分块）：
- 将源文件分割成固定大小的窗口（通常是 16 字节）
- 对每个窗口计算哈希，存入哈希表
- 扫描目标文件，对每个窗口计算哈希，在哈希表中查找匹配
- 找到最长匹配后生成复制指令
- 未匹配的字节生成插入指令

### 5.4 包索引格式（.idx）

索引文件用于在包文件中快速定位对象，避免线性扫描。

```
Idx file 结构（版本 2）:

[头部] [扇区 0] [扇区 1] [扇区 2] [扇区 3] [尾部]

头部 (8 bytes):
  - 4 bytes: 魔数 "\377tOc"（\xff 74 4f 63）
  - 4 bytes: 版本号 2

扇区 0 — 扇区偏移表（fan-out table, 256×4 bytes）:
  每个条目表示 SHA-1 首字节 ≤ 索引值的对象数量
  例如 fanout[0x00] = 5 表示有 5 个以 00 开头的对象
       fanout[0x01] = 8 表示有 8 个以 00 或 01 开头的对象
  这允许二分查找定位对象的扇区

扇区 1 — SHA-1 排序列表（20×N bytes）:
  所有对象 SHA-1 排序后的完整列表

扇区 2 — CRC32 校验和列表（4×N bytes）:
  每个对象解压后数据的 CRC32 值

扇区 3 — 包内偏移量列表（4×N bytes 或 8×N bytes）:
  每个对象在包文件中的偏移量
  最高位为 1 时，低 31 位指向另一个 8 bytes 的偏移量表

尾部 (20 bytes):
  - 包文件的 SHA-1 校验和
  - 索引文件的 SHA-1 校验和
```

**扇区 0 查找优化**：
给定 SHA-1 哈希 `ab...`，先查 `fanout[0xab]` 获得对象在扇区 1 中的大致位置，然后在该范围内进行二分查找。这比全量二分查找减少了约 8 次比较操作。

### 5.5 多包文件（Multi-Pack Index, MIDX）

当存在多个 pack 文件时，`.git/objects/pack/multi-pack-index` 提供跨包查找：

```
MIDX 结构:
  [头部] [扇区 0] [扇区 1] [扇区 2] [尾部]

扇区 0: fan-out table（同 idx）
扇区 1: 排序后的 SHA-1 列表 + 对应的 pack 文件索引 + 包内偏移量
扇区 2: 每个 pack 文件的信息（大小、修改时间等）
```

---

## 6. 索引文件

索引（index，也称暂存区或 cache）是 Git 的核心数据结构，记录即将提交的文件状态。

### 6.1 索引结构

```
Index 文件格式:

[头部] [条目 1] [条目 2] ... [条目 N] [扩展区] [尾部校验和]

头部 (12 bytes):
  - 4 bytes: 签名 "DIRC" (dircache)
  - 4 bytes: 版本号 (2, 3, 或 4)
  - 4 bytes: 条目数量

每个条目 (最少 62 bytes, 版本 2):
  - 4 bytes: ctime_sec        — 文件状态改变时间（秒）
  - 4 bytes: ctime_nsec       — 文件状态改变时间（纳秒）
  - 4 bytes: mtime_sec        — 文件修改时间（秒）
  - 4 bytes: mtime_nsec       — 文件修改时间（纳秒）
  - 4 bytes: dev              — 设备号
  - 4 bytes: ino              — inode 号
  - 4 bytes: mode             — 文件模式 + 权限
  - 4 bytes: uid              — 用户 ID
  - 4 bytes: gid              — 组 ID
  - 4 bytes: file_size        — 文件大小
  - 20 bytes: SHA-1            — blob 对象的哈希
  - 2 bytes: flags            — 标志位（文件名长度等）
  - 可变: 文件名 (以 NUL 结尾) — 路径名
  - 填充: 对齐到 8 字节边界

扩展区（版本 3+）:
  - "TREE" 扩展: 缓存 tree 对象，加速 tree 写入
  - "REUC" 扩展: 解决冲突的条目信息
  - "UNTR" 扩展: 未跟踪目录信息（`git status` 加速）

校验和 (20 bytes):
  - 索引文件内容的 SHA-1
```

### 6.2 索引的作用

1. **暂存区**：记录 `git add` 之后的文件状态
2. **性能缓存**：存储文件元数据（mtime、inode 等），`git status` 可以通过对比文件系统元数据跳过未修改文件，避免重新计算 SHA-1
3. **合并冲突记录**：存储多个版本的相同文件（stage 1/2/3）

### 6.3 合并冲突中的索引

合并冲突时，同一文件可以有多个索引条目，通过 flags 中的 stage 字段区分（版本 2 中在 flags 的高 2 bits）：

- **stage 0** — 正常状态
- **stage 1** — 共同祖先（base）
- **stage 2** — 当前分支（ours）
- **stage 3** — 合并分支（theirs）

```
# 冲突时的索引条目示例
100644 a1b2c3 0   main.c     ← 正常文件
100644 d4e5f6 1   conflict.c ← 共同祖先版本
100644 g7h8i9 2   conflict.c ← 当前分支版本
100644 j0k1l2 3   conflict.c ← 合并分支版本
```

### 6.4 Untracked Cache

在索引的 UNTR 扩展中，存储未跟踪目录的信息，包括目录的 mtime 和其中的文件列表。这样 `git status` 只需要检查目录 mtime 是否变化，如未变化则跳过对该目录的扫描。

---

## 7. 三棵树架构

Git 的工作状态由三个区域组成：工作目录（working directory）、暂存区（index/staging area）、HEAD。

```
        工作目录                 暂存区                  HEAD
     (working tree)           (index)              (commit tree)
    ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
    │  main.c v4   │     │  main.c v3   │     │  main.c v2   │
    │  lib.c  v2   │     │  lib.c  v2   │     │  lib.c  v1   │
    │  new.py v1   │     │  (absent)    │     │  (absent)    │
    └──────┬───────┘     └──────┬───────┘     └──────┬───────┘
           │                    │                    │
           ▼                    ▼                    ▼
     未暂存的修改         未提交的修改           已提交的快照
     (unstaged)           (staged)              (committed)
```

### 7.1 核心命令的内部实现

#### `git add`

```
1. 读取文件内容到内存
2. 构造 blob 对象头: "blob <size>\0"
3. 计算 SHA-1: sha1(header + content)
4. 用 zlib 压缩并写入 .git/objects/
5. 更新 .git/index 中的对应条目（或新增条目）
```

#### `git commit`

```
1. 读取 .git/index 中的所有条目
2. 递归构建 tree 对象（自底向上）:
   a. 按目录分组 index 条目
   b. 为每个子目录构建 tree 对象并写入 .git/objects/
   c. 构建根 tree 对象
3. 构建 commit 对象:
   a. 写入 "tree <root_tree_hash>\n"
   b. 写入 "parent <HEAD_commit_hash>\n"（如果有 parent）
   c. 写入 author/committer 行
   d. 写入提交信息
4. 计算 commit 对象的 SHA-1，写入 .git/objects/
5. 更新 .git/refs/heads/<branch> 为新 commit 的哈希
6. 更新 .git/logs/HEAD 和 .git/logs/refs/heads/<branch>
```

#### `git status`

```
1. 解析 HEAD 指向的 tree 对象 → 得到已提交的文件清单 + 哈希
2. 解析 .git/index → 得到暂存的文件清单 + 哈希 + 元数据
3. 扫描工作目录的每个文件:
   a. 对比文件系统元数据（mtime/dev/ino 等）与 index 条目
   b. 如果元数据匹配 → 文件未修改，跳过
   c. 如果元数据不匹配 → 读取文件内容，计算 SHA-1
   d. 对比 SHA-1 与 index 条目的 SHA-1
   e. 如果不匹配 → 文件已修改（unstaged）
4. 对比 index 的 SHA-1 与 HEAD tree 的 SHA-1:
   a. 匹配 → 已暂存且等于 HEAD（clean）
   b. 不匹配 → 已暂存但与 HEAD 不同（staged）
5. 对比工作目录文件列表与 index 文件列表 → 得到未跟踪文件
```

#### Lazy 元数据检查（Racy Git 问题）

如果文件修改发生在同一秒内，mtime 精度不足以检测变化。Git 通过以下方式解决：

1. 如果 index 条目的 mtime 与当前时间相同（在同一秒内被修改），Git 会将该条目标记为"可能已修改"
2. 在 `git status` 末尾，Git 刷新 index 并检查这些可疑条目
3. 如果发现实际未见修改，更新 index 的 ctime/mtime 以反映真实的检查时间

### 7.2 文件比较的捷径

```c
// git-status 的优化伪代码
if (stat.st_mtime == index_entry.mtime &&
    stat.st_size == index_entry.file_size &&
    stat.st_dev == index_entry.dev &&
    stat.st_ino == index_entry.ino &&
    stat.st_mode == index_entry.mode &&
    stat.st_uid == index_entry.uid &&
    stat.st_gid == index_entry.gid) {
    // 极大概率未修改，跳过
}
```

---

## 8. 合并机制

### 8.1 三路合并（Three-way Merge）

三路合并是 Git 的默认合并策略，需要三个输入：

```
共同祖先 (base)    我们的版本 (ours)    他们的版本 (theirs)
    A                     A'                    A''
```

合并算法对每个文件执行：

```
1. diff(base, ours)  → 我们的修改集
2. diff(base, theirs) → 他们的修改集
3. 组合应用修改：
   - 双方都未修改 → 保持原样
   - 仅一方修改   → 采纳修改
   - 双方修改相同  → 采纳修改（不冲突）
   - 双方不同修改  → 冲突，标记冲突区域
```

### 8.2 合并冲突标记

```
<<<<<<< HEAD
我们的版本
=======
他们的版本
>>>>>>> branch-name
```

### 8.3 递归合并策略（Recursive Merge）

当涉及多个共同祖先时（如"合并"两个有交叉历史的仓库），Git 递归合并共同祖先：

```
算法:
1. 查找所有共同祖先
2. 如果有多个共同祖先，先合并共同祖先（递归）
3. 用合并后的共同祖先作为 base 进行三路合并
```

### 8.4 实际合并算法（xdiff 库）

Git 使用 LibXDiff 库进行差异计算和合并。

**Myer's Diff 算法**：

寻找两个序列的最短编辑脚本（SES / Shortest Edit Script），即将一个序列转换为另一个所需的最少操作数。

```
核心概念 — 编辑图（Edit Graph）:
  将序列 A（长度 N）和 B（长度 M）映射到图上的 (0,0) 到 (N,M)
  向右移动 = 删除 A 中的一个元素
  向下移动 = 插入 B 中的一个元素
  对角移动 = 匹配（无需操作）

  目标: 从 (0,0) 到 (N,M) 的最短路径
  对角线越多的路径表示匹配越多

Myers 算法的关键洞见:
  在 k 对角线上的路径，其终点 (x,y) 满足 x - y = k
  d 轮迭代的 d 值表示允许的编辑步数
  从 d=0 开始递增，每轮扩展所有可能的路径
  找到第一条到达 (N,M) 的路径即为 SES
```

**Patience Diff**（`git diff --patience`）：

比 Myer's Diff 产生更可读的结果：

```
1. 找到两文件中都唯一且顺序相同的行（独特的共同行）
2. 以这些行为锚点，将文件分割成更小的块
3. 在每个块内递归应用该过程
4. 对剩余无法匹配的块使用 Myer's Diff
```

**Histogram Diff**（Git 默认的 diff 算法）：

比 Patience Diff 更快，产生类似质量的结果：

```
1. 统计文件 B 中每行出现的次数
2. 找出 B 中出现次数最少的行
3. 如果该行也在 A 中出现，以它为锚点分割
4. 递归处理分割后的块
```

### 8.5 变基（Rebase）的内部实现

变基不是合并，而是将一系列 commit 在新的 base 上重放：

```
原始:
  A---B---C (feature)
 /
D---E---F (main)

rebase 后:
          B'---C' (feature)
         /
  D---E---F (main)

实现过程:
1. 找出 feature 分支从 main 分叉后的 commit 列表 [B, C]
2. 将 HEAD 指向 F（main 的最新 commit）
3. 对 B 应用 `git cherry-pick`:
   a. 计算 B 与 A 的差异
   b. 将该差异应用到 F 上
   c. 创建新的 commit B'（不同的 parent、不同的时间戳 → 不同的哈希）
4. 对 C 执行类似操作，得到 C'
5. 将 feature 引用指向 C'
```

### 8.6 快进合并 vs 非快进合并

```
快进合并（Fast-forward）:
  初始: A---B (main) → 指向 B
         \
          C---D (feature)
  合并后: A---B---C---D (main, feature 都指向 D)
  实质: 只是移动指针

非快进合并（--no-ff）:
  初始: A---B---C (main)
         \
          D---E (feature)
  合并后: A---B---C---F (main, 创建新的合并 commit F)
                \     /
                 D---E (feature)
```

---

## 9. 传输协议

### 9.1 哑协议（Dumb Protocol）

通过 HTTP/FTP 直接暴露 `.git` 目录（现已很少使用）：

```
1. 客户端获取 .git/HEAD 知道默认分支
2. 客户端获取 .git/refs/heads/* 获取所有分支指向的 commit
3. 客户端获取 .git/objects/ 下的对象
4. 对于 pack 文件，获取 .git/objects/pack/ 及其索引
```

### 9.2 智能协议（Smart Protocol）

Git 的智能协议使用 SSH、git:// 或 HTTP(S) 传输，通过包线（pkt-line）格式通信。

**pkt-line 格式**：

```
每个数据块以 4 字节十六进制长度前缀开始：
"000a" + "hello\n"  →  10 bytes 的 "hello\n"
长度包括 4 字节前缀本身
"0000" → 终止消息（数据边界标记）
"0001" → 分隔符
"0002" → flush 之后的更多数据标记
"0003" → 预留标记
```

**取数据（fetch）流程**：

```
客户端 → 服务器:
  "git-upload-pack /path/to/repo\0host=example.com\0"

服务器 → 客户端:
  <refs 列表> + capabilities
  "0000"

客户端 → 服务器:
  "want <commit_hash>\n"  (想要的 commit)
  "have <commit_hash>\n"  (已有的 commit)
  "done\n"
  "0000"

服务器 → 客户端:
  发送 packfile（包含客户端 want 的 commit 及其祖先中客户端 have 缺失的对象）
```

**推数据（push）流程**：

```
客户端 → 服务器:
  "git-receive-pack /path/to/repo\0host=example.com\0"

服务器 → 客户端:
  <refs 列表> + capabilities

客户端 → 服务器:
  "<old_sha1> <new_sha1> refs/heads/main\0<capabilities>"
  packfile（包含 new_sha1 到 old_sha1 之间所有新对象）

服务器 → 客户端:
  "ok refs/heads/main\n"
  "ng refs/heads/feature <error_message>\n"
  "0000"
```

### 9.3 协议能力（Capabilities）

双方协商支持的扩展功能：

```
multi_ack      — 支持多个 ACK（优化协商）
ofs-delta      — 支持偏移量增量
side-band      — 支持边带（进度信息与数据分离）
side-band-64k  — 64K 边带
thin-pack      — 支持精简包（使用对方已有对象做增量基）
no-progress    — 不发送进度信息
include-tag    — 推送时包含标签对象
report-status  — 报告推送结果到每个引用
```

### 9.4 边带（Side-band）协议

在 fetch 过程中，数据通道（channel）被分为两个边带：

```
channel 1: packfile 数据
channel 2: 进度信息（"Receiving objects: 45%"）
channel 3: 致命错误
```

每个数据包通过边带编号标识其所属通道。

### 9.5 Negotiation 算法

Git 的 fetch negotiation 优化策略：

**原始算法**（Git < 2.27）：
- 客户端发送最短路径上所有 `have`
- 服务器通过 `ACK` / `NAK` 响应
- 当客户端收到连续 `ACK` 时，停止发送更多 `have`

**Fetch Negotiation v2**（protocol v2）：
- 服务器端可以推送 ref 的 tip commit
- 客户端发送 `have`，服务器回复能够 reach 的最小 commit
- 使用 `packfile-uris` 支持 CDN 分发

---

## 10. 垃圾回收

### 10.1 何时触发

```
条件                    默认阈值                      配置项
松散对象数量 >          gc.auto = 6700               gc.auto
包文件数量 >            gc.autopacklimit = 50        gc.autopacklimit
git gc 显式调用          —                            —
```

### 10.2 执行过程

```
git gc 的步骤:

1. 收集所有可达对象（从 refs、index、reflog 等追踪的 commit/tree/blob/tag）
   - 执行 `git reflog expire --expire-unreachable=90.days.ago`
     删除超过 90 天且不可达的 reflog 条目
   - 执行 `git prune --expire=2.weeks.ago`
     删除不可达且超过 2 周的松散对象

2. 打包对象
   - 将松散对象打包为 packfile
   - 合并已有的 packfile（减少 pack 文件数量）
   - 应用增量压缩（delta compression）

3. 清理
   - 删除原始松散对象文件
   - 重写引用（生成 packed-refs）
   - 删除已合并的旧 pack 文件
```

### 10.3 可达性分析（Reachability）

```
可达对象 = 从以下任一入口可遍历到达的对象:

入口点:
  - refs/heads/*  (所有分支)
  - refs/tags/*   (所有标签)
  - refs/remotes/* (远程跟踪分支)
  - HEAD 的 reflog
  - 索引文件中的 blob
  - 其他临时引用 (MERGE_HEAD, FETCH_HEAD 等)

不可达对象 = "悬浮"的对象，包括:
  - 被 `git reset` 丢弃的旧 commit
  - `git rebase` 中替换掉的旧 commit
  - 被新 blob 替换的旧文件内容
```

### 10.4 增量压缩的分层策略（Window）

```
1. 将对象按类型分组（commit/tree/blob）
2. 对每种类型，在滑动窗口中寻找最佳增量基:
   - 窗口大小: 默认 250 个对象（gc.window = 250）
   - 对窗口内的每对对象，计算 delta
   - 选择最优的 delta（压缩率最高的）
3. 构建 delta 链:
   base → delta1 → delta2 → ... → deltaN
   注意: 检索时需要解压整条链，所以链不宜过长
   Git 限制最大 delta 深度: gc.depth = 50
```

### 10.5 位图（Bitmap）索引

为加速 clone/fetch，Git 可以为包文件建立位图索引：

```
.bitmap 文件包含:
  - 所有对象的位图（每个对象对应一个 bit）
  - 对于每个 commit，位图表示其可达的所有对象
  - 使用 EWAH（Enhanced Word-Aligned Hybrid）压缩存储

clone 加速:
  当服务器接收到 want 列表时:
  1. 查找客户端 want 的 commit 的位图
  2. 对每个想要但客户端没有的 commit，用位图快速计算需要发送的对象
  3. 计算需要的 pack 文件 → 无需遍历整个对象图
```

---

## 附录

### A. `git hash-object` 手动创建对象示例

```bash
# 手动创建一个 blob 对象
echo "hello world" | git hash-object -w --stdin
# 输出: 3b18e512dba79e4c8300dd08aeb37f8e728b8dad

# 查看存储的内容
cat .git/objects/3b/18e512dba79e4c8300dd08aeb37f8e728b8dad | openssl zlib -d
# 输出: blob 12\0hello world\n

# 手动创建一个 tree 对象
git ls-tree HEAD | git mktree
```

### B. `git write-tree` 和 `git commit-tree`

```bash
# 根据 index 生成 tree 对象并写入 object store
git write-tree

# 手动创建 commit 对象
echo "commit msg" | git commit-tree <tree_hash> -p <parent_hash>
```

### C. 关键配置参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `core.compression` | -1 (zlib 默认) | 松散对象的压缩级别 |
| `core.deltaBaseCacheLimit` | 96 MB | 增量解压缓存大小 |
| `gc.auto` | 6700 | 触发 gc 的松散对象数 |
| `gc.autopacklimit` | 50 | 触发 gc 的包文件数 |
| `gc.depth` | 50 | 最大增量链深度 |
| `gc.window` | 250 | 增量压缩搜索窗口大小 |
| `pack.windowMemory` | 无限制 | 增量窗口内存上限 |
| `pack.deltaCacheSize` | 0 (无限制) | 增量缓存大小 |
| `core.preloadIndex` | true | 并行预加载索引（加速 status） |
| `core.untrackedCache` | false | 启用未跟踪缓存（加速 status） |
