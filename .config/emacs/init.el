;;; init.el — 入口文件
;;; 基础设施（包管理、备份、会话恢复）+ 加载各模块

;; ============================================================
;; 自定义设置（Customize UI 存到这里）
;; ============================================================
(setq custom-file "~/.local/share/emacs/custom.el")
(load custom-file t)

;; ============================================================
;; 包管理
;; ============================================================
(require 'package)
(setq package-user-dir "~/.local/share/emacs/elpa")
(setq package-archives
      '(("gnu"            . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
        ("melpa"          . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")
        ("gnu-ustc"       . "https://mirrors.ustc.edu.cn/elpa/gnu/")
        ("melpa-ustc"     . "https://mirrors.ustc.edu.cn/elpa/melpa/")
        ("gnu-official"   . "https://elpa.gnu.org/packages/")
        ("melpa-official" . "https://melpa.org/packages/")))

(setq package-archive-priorities
      '(("gnu"            . 10)
        ("melpa"          . 10)
        ("gnu-ustc"       . 5)
        ("melpa-ustc"     . 5)
        ("gnu-official"   . 1)
        ("melpa-official" . 1)))
(package-initialize)


;; ============================================================
;; 个人lisp代码，都放在.emacs/lisp/。配置都在modules
;; ============================================================
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(add-to-list 'load-path "~/.dotfiles/.config/emacs/modules")


;; ============================================================
;; 加载模块（keymaps 最后加载，以便引用各模块中的函数）
;; ============================================================
(require 'path)
(require 'options)
(require 'ui)
(require 'vim)
(require 'writing)
(require 'filetree)
(require 'my-org)
(require 'lsp)
(require 'file-search)
(require 'my-eaf)
(require 'keymaps)





;; 主题加载
(load-theme 'doom-dracula t)
; (load-theme 'doom-earl-grey t)


