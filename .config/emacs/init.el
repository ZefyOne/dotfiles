;;; init.el — 入口文件
;;; 基础设施（包管理、备份、会话恢复）+ 加载各模块

;; ============================================================
;; 自定义设置（Customize UI 存到这里）
;; ============================================================
(setq custom-file "~/.config/emacs/custom.el")
(load custom-file t)

;; ============================================================
;; 包管理
;; ============================================================
(require 'package)
(setq package-user-dir "~/.config/emacs/elpa")
(setq package-archives '(("gnu"   . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
                         ("melpa" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")))
(package-initialize)

;; ============================================================
;; 备份与自动保存
;; ============================================================
(unless (file-exists-p "~/.config/emacs/backups/")
  (make-directory "~/.config/emacs/backups/" t))
(setq backup-directory-alist '(("." . "~/.config/emacs/backups/"))
      auto-save-file-name-transforms '((".*" "~/.config/emacs/backups/" t))
      auto-save-list-file-prefix "~/.config/emacs/backups/sessions-")

(setq auto-save-timeout 120
      auto-save-interval 300)

;; ============================================================
;; 会话恢复
;; ============================================================
(desktop-save-mode 1)
(setq desktop-path '("~/.config/emacs/"))
(setq desktop-dirname "~/.config/emacs/")
(setq desktop-save t)
(setq desktop-auto-save-timeout 300)
;; 不让 desktop 保存颜色相关参数，避免覆盖主题
(require 'frameset)
(dolist (p '(background-color foreground-color background-mode
              cursor-color mouse-color border-color))
  (push (cons p :never) frameset-filter-alist))

;; ============================================================
;; 加载模块（keymaps 最后加载，以便引用各模块中的函数）
;; ============================================================
(add-to-list 'load-path "~/.config/emacs/modules")
(require 'options)
(require 'ui)
(require 'vim)
(require 'writing)
(require 'filetree)
(require 'my-org)
(require 'file-search)
(require 'keymaps)

(add-to-list 'load-path "/home/zefy/Desktop/blink-search")

(require 'blink-search)
