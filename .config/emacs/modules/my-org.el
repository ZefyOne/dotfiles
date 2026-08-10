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
        org-adapt-indentation nil
        org-startup-with-inline-images t
        org-startup-indented t
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-image-actual-width nil
        org-imenu-depth 8)
  ;; 关闭 electric-indent-mode 防止 RET 后自动插入制表符
  (add-hook 'org-mode-hook (lambda () (electric-indent-local-mode -1)))
  :config
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
  ;; return 主题让 RET 在列表内续接（1. → 2.），改完必须重新应用主题
  (setq evil-org-key-theme '(textobjects navigation additional todo return))
  (evil-org-set-key-theme))

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
          (?- . ?● ))))
 
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
;; 加粗 — org-emphasize 封装，i 模式 C-c b
;; ============================================================
(defun my/org-bold ()
  "有选中区域时用一对 * 包裹（纯字符插入，不加空格）；
否则插入 ** 光标居中。"
  (interactive)
  (if (use-region-p)
      (let ((beg (region-beginning))
            (end (region-end)))
        (save-excursion
          (goto-char end)
          (insert "*")
          (goto-char beg)
          (insert "*"))
        (deactivate-mark))
    (insert "**")
    (backward-char 1)))

(provide 'my-org)
