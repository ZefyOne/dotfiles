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
(setq package-archives '(("gnu"   . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
                         ("melpa" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")))
(package-initialize)




;; ============================================================
;; 备份与自动保存
;; ============================================================
(unless (file-exists-p "~/.local/state/emacs/backups/")
  (make-directory "~/.local/state/emacs/backups/" t))
(setq backup-directory-alist '(("." . "~/.local/state/emacs/backups/"))
      auto-save-file-name-transforms '((".*" "~/.local/state/emacs/backups/" t))
      auto-save-list-file-prefix "~/.local/state/emacs/backups/sessions-")

(setq auto-save-timeout 120
      auto-save-interval 300)

;; ============================================================
;; 会话恢复
;; ============================================================
(desktop-save-mode 1)
(setq desktop-path '("~/.local/state/emacs/"))
(setq desktop-dirname "~/.local/state/emacs/")
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
(setq save-place-file "~/.local/state/emacs/places")
(setq recentf-save-file "~/.local/state/emacs/recentf")
(setq tramp-persistency-file-name "~/.local/state/emacs/tramp")
(setq projectile-bookmarks-file "~/.local/state/emacs/projectile/projectile-bookmarks.eld"
      projectile-known-projects-file "~/.local/state/emacs/projectile/projectile-known-projects.eld"
      projectile-frecency-file "~/.local/state/emacs/projectile/projectile-frecency.eld")
(setq transient-levels-file "~/.local/state/emacs/transient/levels"
      transient-values-file "~/.local/state/emacs/transient/values"
      transient-history-file "~/.local/state/emacs/transient/history")
(setq undo-fu-session-directory "~/.local/state/emacs/undo/")

;; ============================================================
;; 缓存路径（native-comp 编译产物 / treemacs 持久状态）
;; ============================================================
(add-to-list 'native-comp-eln-load-path "~/.cache/emacs/eln-cache/")
(setq treemacs-persist-file "~/.cache/emacs/treemacs-persist")

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
;; eaf框架（目录存在才加载，避免新电脑未 clone EAF 时崩溃）
;; ============================================================
(when (file-exists-p "~/.local/share/emacs/site-lisp/emacs-application-framework/")
  (add-to-list 'load-path "~/.local/share/emacs/site-lisp/emacs-application-framework/")
  (setq eaf-python-command "~/.dotfiles/.config/emacs/.python-env/bin/python")

  ;; EAF 数据目录 → ~/.local/share/emacs/eaf/
  (setq eaf-config-location "~/.local/share/emacs/eaf/")

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

  ;; 给浏览器插件换搜索引擎
  (setq eaf-browser-default-search-engine "bing"))
; (setenv "QT_MEDIA_BACKEND" "gstreamer")
;; 主题加载
; (load-theme 'doom-dracula t)
(load-theme 'doom-earl-grey t)

;(org-babel-do-load-languages
; 'org-babel-load-languages
; '((python . t)))
