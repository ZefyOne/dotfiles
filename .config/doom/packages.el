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
