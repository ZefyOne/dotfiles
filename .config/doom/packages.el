;;; $DOOMDIR/packages.el -*- lexical-binding: t; no-byte-compile: t -*-

;; 安装一个包的方法：
;;
;;   1. 在这里用 `package!' 语句声明它们，
;;   2. 在 shell 里运行 'doom sync'，
;;   3. 重启 Emacs。
;;
;; 用 'C-h f package\!' 查看 `package!' 宏的文档。


;; 从 MELPA、ELPA 或 emacsmirror 安装 SOME-PACKAGE：
;; (package! some-package)

;; 想直接从远程 git 仓库安装包，必须指定 `:recipe'。
;; `:recipe' 接受哪些内容，文档在这里：
;; https://github.com/radian-software/straight.el#the-recipe-format
;; (package! another-package
;;   :recipe (:host github :repo "username/repo"))

;; 如果你要装的包里没有 PACKAGENAME.el 文件，或者它位于仓库的子目录中，
;; 就需要在 `:recipe' 里指定 `:files'：
;; (package! this-package
;;   :recipe (:host github :repo "username/repo"
;;            :files ("some-file.el" "src/lisp/*.el")))

;; 如果你想禁用 Doom 自带的某个包，可以在这里用 `:disable' 属性做到：
;; (package! builtin-package :disable t)

;; 你可以覆盖内置包的 recipe，而不必写出 `:recipe' 的所有属性。
;; 其余部分会继承 Doom 或 MELPA/ELPA/Emacsmirror 中的 recipe：
;; (package! builtin-package :recipe (:nonrecursive t))
;; (package! builtin-package-2 :recipe (:repo "myfork/package"))

;; 用 `:branch' 指定从某个特定分支或标签安装包。
;; 有些包的默认分支不是 'master'，这时必须指定它
;; （我们的包管理器处理不了这种情况；见 radian-software/straight.el#279）
;; (package! builtin-package :recipe (:branch "develop"))

;; 用 `:pin' 指定安装某个特定的 commit。
;; (package! builtin-package :pin "1a2b3c4d5e")


;; Doom 的包都固定在特定的 commit 上，并随版本发布而更新。
;; `unpin!' 宏可以让你取消固定单个包……
;; (unpin! pinned-package)
;; ……或多个包
;; (unpin! pinned-package another-pinned-package)
;; ……或者*所有*包（不推荐；大概率会把配置弄坏）
;; (unpin! t)

(package! rime)

(package! isearch-mb)

(package! valign)

;; org-roam-ui —— Obsidian 风格的交互式网状图（2D 圆点 / 3D 球体）。
;;
;; 为什么要 unpin：org-roam-ui 要跟 org-roam 的新 API 走（比如它靠
;; `org-roam-db-map-citations' 是否存在来判断新旧引用格式），而 Doom 习惯把
;; org-roam 钉在某个固定 commit 上。
;;
;; 实测（2026-09）：当前 pin 恰好就是 main 顶端 903bd4e，所以这行**现在不会
;; 触发任何重新下载或重编译**。它真正的价值在将来 —— 防止 doom upgrade 把
;; org-roam 钉回更老的版本，导致图里引用链接那块静默降级。
(unpin! org-roam)
(package! org-roam-ui)

(package! poet-theme
  :recipe (:host github :repo "kunalb/poet"))

;; Everforest 主题 —— MELPA 上没有（已核对 melpa.org 全量包名 6324 个，只有
;; calmer-forest-theme / forest-blue-theme），所以必须走 Git recipe，不能裸写
;; (package! everforest)。
;;
;; 注意这不是 sainnhe 的官方版：官方只做了 Vim/Neovim 和 VS Code（后者也已停更），
;; Emacs 侧一直是第三方移植 —— 官方 wiki 的 related projects 里也是把 Emacs 和
;; Doom Emacs 两个端口都归在第三方名下。这个是其中唯一还在维护的；另一个
;; Cardoso1994/doom-everforest-theme 有 soft/medium 对比度，但 2022-12 后停更。
;;
;; sr.ht 是该移植项目自己的主仓库，codeberg 是镜像，两个都能 git ls-remote 通。
;;
;; :files 把 everforest.el 排除在构建目录外，这是必须的 —— 上游那个文件第 25
;; 行有个 `;;;###autoload' cookie，但它后面除了注释什么都没有（本该被标注的
;; 代码被作者注释掉了）。Emacs 的 loaddefs 生成器读到 cookie 会去 read 下一个
;; 表达式，直接撞上文件尾，于是 doom sync 报：
;;
;;   ("everforest" (end-of-file #<killed buffer>))
;;
;; 三个文件里只有 everforest.el 这个是坏的：两个 *-theme.el 的同名 cookie 后面
;; 跟着真实代码，作用是自注册 custom-theme-load-path。所以只要把这个坏文件剔出
;; 构建目录，autoloads 就能正常生成，主题也就能像 poet 一样被自动找到 ——
;; 不需要在 config 里手动 add-to-list（那反而要引用 straight 内部变量，
;; 而 straight-base-dir 在 config.el 执行时还没绑定）。
;;
;; 显式列出两个文件而不是用 (:defaults (:exclude ...))：语义最明确，不依赖
;; :defaults 的拼接规则。代价是将来上游加了 soft/medium 的新主题文件，这里要
;; 手动补上。
(package! everforest
  :recipe (:repo "https://git.sr.ht/~theorytoe/everforest-theme"
           :files ("everforest-hard-dark-theme.el"
                   "everforest-hard-light-theme.el")))
