;;; org.el — Org-mode（任务管理、笔记、日程）

;; ============================================================
;; org — 核心设置
;; ============================================================
(use-package org
  :ensure t
  :defer t
  :init
  (setq org-directory "~/org"
        org-default-notes-file "~/org/notes.org"
        org-log-done 'time
        org-startup-with-inline-images t
        org-startup-indented t
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-image-actual-width nil
        org-imenu-depth 8)
  :config
  ;; Normal state 下 RET 打开链接
  (evil-define-key 'normal org-mode-map (kbd "RET") 'org-open-at-point)

  ;; org-capture 的确认/取消快捷键
  (with-eval-after-load 'org-capture
    (evil-define-key 'normal org-capture-mode-map
      (kbd "c") 'org-capture-finalize
      (kbd "k") 'org-capture-kill
      (kbd "r") 'org-capture-refile))

  ;; org-src 编辑快捷键
  (with-eval-after-load 'org-src
    (evil-define-key 'normal org-src-mode-map
      (kbd "c") 'org-edit-src-exit
      (kbd "k") 'org-edit-src-abort))

  ;; 代码块执行后刷新内联图片
  (add-hook 'org-babel-after-execute-hook
            (lambda ()
              (when org-inline-image-overlays
                (org-redisplay-inline-images)))))

;; ============================================================
;; evil-org — Vim 风格操作
;; ============================================================
(use-package evil-org
  :ensure t
  :after org
  :config
  (add-hook 'org-mode-hook 'evil-org-mode)
  (setq evil-org-key-theme '(textobjects navigation additional todo)))

;; ============================================================
;; org-superstar — 美化标题星号和待办标记
;; ============================================================
(use-package org-superstar
  :ensure t
  :hook (org-mode . org-superstar-mode)
  :config
  ;; 列表项符号渲染：- → •, + → ➤, * → •
  (setq org-superstar-prettify-item-bullets t
        org-superstar-item-bullet-alist
        '((?* . ?•)
          (?+ . ?➤)
          (?- . ?⬤))))

;; ============================================================
;; org-download — 拖拽/粘贴图片到附件
;; ============================================================
(use-package org-download
  :ensure t
  :hook (org-mode . org-download-enable))

;; ============================================================
;; htmlize — 导出 HTML 时代码语法高亮
;; ============================================================
(use-package htmlize
  :ensure t
  :defer t)

;; ============================================================
;; 全局快捷键（Spacemacs 风格：SPC a o）
;; ============================================================

;; SPC a — Applications
(define-prefix-command 'my-apps-prefix-map)
(put 'my-apps-prefix-map 'which-key-description "Applications")
(define-key my-leader-map (kbd "a") my-apps-prefix-map)

;; SPC a o — Org
(define-prefix-command 'my-org-apps-prefix-map)
(put 'my-org-apps-prefix-map 'which-key-description "Org")
(define-key my-apps-prefix-map (kbd "o") my-org-apps-prefix-map)

;; SPC a o a — 日程
(define-key my-org-apps-prefix-map (kbd "a") 'org-agenda)
;; SPC a o c — 快速捕获
(define-key my-org-apps-prefix-map (kbd "c") 'org-capture)
;; SPC a o l — 存储链接
(define-key my-org-apps-prefix-map (kbd "l") 'org-store-link)
;; SPC a o t — TODO 列表
(define-key my-org-apps-prefix-map (kbd "t") 'org-todo-list)
;; SPC a o s — 搜索
(define-key my-org-apps-prefix-map (kbd "s") 'org-search-view)
;; SPC a o # — 阻塞项目
(define-key my-org-apps-prefix-map (kbd "#") 'org-agenda-list-stuck-projects)

;; ============================================================
;; org-mode 内快捷键（编辑操作、TODO、子树等）
;; ============================================================
(with-eval-after-load 'org
  (evil-define-key 'normal org-mode-map
    ;; TODO
    (kbd "C-c C-t") 'org-todo
    ;; 日期
    (kbd "C-c .")   'org-time-stamp
    (kbd "C-c C-d") 'org-deadline
    (kbd "C-c C-s") 'org-schedule
    ;; 链接
    (kbd "C-c C-o") 'org-open-at-point
    ;; 附件
    (kbd "C-c C-a") 'org-attach
    ;; 移动子树
    (kbd "M-h") 'org-promote-subtree
    (kbd "M-l") 'org-demote-subtree
    (kbd "M-j") 'org-move-subtree-down
    (kbd "M-k") 'org-move-subtree-up
    ;; 表格
    (kbd "C-c RET") 'org-table-create
    (kbd "C-c |")   'org-table-create-with-table.el
    ;; 切换开关
    (kbd "C-c C-x C-l") 'org-latex-preview
    (kbd "C-c C-x C-i") 'org-toggle-inline-images))

(provide 'my-org)
