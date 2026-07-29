;;; init.el — 入口文件
;;; 基础设施（包管理、备份、会话恢复）+ 加载各模块

;; ============================================================
;; 自定义设置（Customize UI 存到这里）
;; ============================================================
(setq custom-file "~/.dotfiles/.config/emacs/local/custom.el")
(load custom-file t)

;; ============================================================
;; 包管理
;; ============================================================
(require 'package)
(setq package-user-dir "~/.dotfiles/.config/emacs/local/elpa")
(setq package-archives '(("gnu"   . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
                         ("melpa" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")))
(package-initialize)




;; ============================================================
;; 备份与自动保存
;; ============================================================
(unless (file-exists-p "~/.dotfiles/.config/emacs/local/backups/")
  (make-directory "~/.dotfiles/.config/emacs/local/backups/" t))
(setq backup-directory-alist '(("." . "~/.dotfiles/.config/emacs/local/backups/"))
      auto-save-file-name-transforms '((".*" "~/.dotfiles/.config/emacs/local/backups/" t))
      auto-save-list-file-prefix "~/.dotfiles/.config/emacs/local/backups/sessions-")

(setq auto-save-timeout 120
      auto-save-interval 300)

;; ============================================================
;; 会话恢复
;; ============================================================
(desktop-save-mode 1)
(setq desktop-path '("~/.dotfiles/.config/emacs/local/state/"))
(setq desktop-dirname "~/.dotfiles/.config/emacs/local/state/")
(setq desktop-save t)
(setq desktop-auto-save-timeout 300)
;; 不让 desktop 保存颜色相关参数，避免覆盖主题
(require 'frameset)
(dolist (p '(background-color foreground-color background-mode
              cursor-color mouse-color border-color
              menu-bar-lines tool-bar-lines tab-bar-lines))
  (push (cons p :never) frameset-filter-alist))

;; ============================================================
;; 其他存储路径（各功能默认写 ~/.emacs.d/，统一集中管理）
;; ============================================================
(setq save-place-file "~/.dotfiles/.config/emacs/local/state/places")
(setq recentf-save-file "~/.dotfiles/.config/emacs/local/state/recentf")
(setq tramp-persistency-file-name "~/.dotfiles/.config/emacs/local/state/tramp")
(setq projectile-bookmarks-file "~/.dotfiles/.config/emacs/local/state/projectile/projectile-bookmarks.eld"
      projectile-known-projects-file "~/.dotfiles/.config/emacs/local/state/projectile/projectile-known-projects.eld")
(setq transient-levels-file "~/.dotfiles/.config/emacs/local/state/transient/levels"
      transient-values-file "~/.dotfiles/.config/emacs/local/state/transient/values"
      transient-history-file "~/.dotfiles/.config/emacs/local/state/transient/history")
(setq undo-fu-session-directory "~/.dotfiles/.config/emacs/local/state/undo/")

;; ============================================================
;; 加载模块（keymaps 最后加载，以便引用各模块中的函数）
;; ============================================================
(add-to-list 'load-path "~/.dotfiles/.config/emacs/modules")
(require 'options)
(require 'ui)
(require 'vim)
(require 'writing)
(require 'filetree)
(require 'my-org)
(require 'lsp)
(require 'file-search)
(require 'keymaps)



;; ============================================================
;; eaf框架
;; ============================================================
(add-to-list 'load-path "~/.emacs.d/site-lisp/emacs-application-framework/")
(setq eaf-python-command "/home/zefy/.emacs.d/.python-env/bin/python")

(require 'eaf)
(require 'eaf-video-player)
(require 'eaf-pdf-viewer)
(require 'eaf-js-video-player)
(require 'eaf-git)
(require 'eaf-image-viewer)
(require 'eaf-browser)
(require 'eaf-camera)
(require 'eaf-org-previewer)
(require 'eaf-file-manager)
(require 'eaf-rss-reader)
(require 'eaf-terminal)
(require 'eaf-music-player)
(require 'eaf-markdown-previewer)


;; 主题加载
; (load-theme 'doom-dracula t)
(load-theme 'doom-earl-grey t)

