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
(unless (file-exists-p "~/.local/state/emacs/projectile/")
  (make-directory "~/.local/state/emacs/projectile/" t))
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



(provide 'path)
