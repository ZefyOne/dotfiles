;;; filetree.el — 侧边栏文件树 (Treemacs)

;; ============================================================
;; which-key — 按前缀键后弹出可用按键提示
;; ============================================================
(use-package which-key
  :ensure t
  :config
  (which-key-mode 1))

;; ============================================================
;; projectile — 项目管理（自动识别项目根）
;; ============================================================
(use-package projectile
  :ensure t
  :config
  (projectile-mode 1))

;; ============================================================
;; nerd-icons — 图标字体（需 M-x nerd-icons-install-fonts）
;; ============================================================
(use-package nerd-icons
  :ensure t)

;; ============================================================
;; treemacs — 侧边栏文件树
;; ============================================================
(use-package treemacs
  :ensure t
  :init
  (setq treemacs-follow-after-init t)
  :config
  (setq treemacs-use-follow-mode t
        treemacs-use-filewatch-mode t
        treemacs-use-git-mode 'deferred
        treemacs-icon-theme 'nerd-icons)
  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-git-mode 'deferred)

  ;; 打开时自动添加当前 projectile 项目
  (defun my/treemacs ()
    "打开 treemacs，若工作区为空则自动添加当前项目。"
    (interactive)
    (when (not (treemacs-current-workspace))
      (treemacs--find-workspace))
    (when (and (bound-and-true-p projectile-mode)
               (projectile-project-p))
      (let ((path (projectile-project-root))
            (name (projectile-project-name)))
        (treemacs-do-add-project-to-workspace path name)))
    (treemacs))

  ;; 在项目根打开/切换 treemacs
  (defun my/treemacs-project-toggle ()
    "在当前项目中打开/切换 treemacs。"
    (interactive)
    (if (eq (treemacs-current-visibility) 'visible)
        (delete-window (treemacs-get-local-window))
      (let ((path (projectile-ensure-project (projectile-project-root)))
            (name (projectile-project-name)))
        (unless (treemacs-current-workspace)
          (treemacs--find-workspace))
        (treemacs-do-add-project-to-workspace path name)
        (treemacs-select-window)))))

;; ============================================================
;; treemacs-evil — Evil 状态键绑定
;; ============================================================
(use-package treemacs-evil
  :ensure t
  :after (treemacs evil))

;; ============================================================
;; treemacs-projectile — 与 projectile 联动
;; ============================================================
(use-package treemacs-projectile
  :ensure t
  :after (treemacs projectile)
  :defer t
  :init (require 'treemacs-projectile))

(provide 'filetree)
