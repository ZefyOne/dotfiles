;;; writing.el — 写作功能

;; ============================================================
;; 中文引号自动配对
;; ============================================================
(setq electric-pair-pairs
      '((?\" . ?\")
        (?「 . ?」)
        (?' . ?')
        (?【 . ?】)
        (?《 . ?》)))

(electric-pair-mode 1)

;; ============================================================
;; 字数统计
;; ============================================================
(defun writing--count-non-space (begin end)
  "计算区域内的非空白字符数（标点也算，空白不算）。"
  (- (- end begin)
     (how-many "[[:space:]]" begin end)))

(let ((enc '(:eval (format " %s"
                           (upcase (symbol-name
                                    (coding-system-base
                                     (or buffer-file-coding-system 'utf-8)))))))
      (wc  '(:eval (if (use-region-p)
                       (format " 字数:%d 选中:%d"
                               (writing--count-non-space (point-min) (point-max))
                               (writing--count-non-space (region-beginning) (region-end)))
                     (format " 字数:%d"
                             (writing--count-non-space (point-min) (point-max)))))))
  (dolist (item (list enc wc))
    (or (memq item mode-line-format)
        (setq-default mode-line-format
                      (append mode-line-format (list item))))))

;; ============================================================
;; 专注模式 (olivetti)
;; ============================================================
(use-package olivetti
  :ensure t
  :config
  (setq olivetti-body-width 80
        olivetti-minimum-body-width 60
        olivetti-recall-visual-line-mode-entry-state t))

;; ============================================================
;; 中文输入 (rime)
;; ============================================================
(use-package rime
  :ensure t
  :custom
  (rime-user-data-dir "~/.dotfiles/.config/emacs/rime/")
  (rime-show-candidate 'minibuffer)
  (default-input-method "rime")
  (rime-disable-predicates '(evil-normal-state-p)))

;; isearch 改用 minibuffer 输入：让 rime 在 isearch 里能正常上屏中文
;; 若候选显示与 minibuffer 输入抢显示，需把 rime-show-candidate 改为 'posframe
(use-package isearch-mb
  :ensure t
  :config
  (isearch-mb-mode 1)
  ;; isearch 输入区复用编辑键（与 file-search 的 vertico-map 保持一致）
  (define-key isearch-mb-minibuffer-map (kbd "C-u")
    (lambda () (interactive) (kill-line 0)))
  (define-key isearch-mb-minibuffer-map (kbd "C-w") 'backward-kill-word))

(defvar my-rime-extensions '("md" "txt" "org")
  "文件后缀，打开时自动激活 rime。")

;; 所有 buffer 默认启用 rime
(run-with-idle-timer 1 nil
  (lambda ()
    (require 'rime)
    (dolist (b (buffer-list))
      (with-current-buffer b
        (when (and (buffer-file-name)
                   (member (file-name-extension (buffer-file-name))
                           my-rime-extensions))
          (activate-input-method "rime"))))))

;; 新打开的文件也启用
(add-hook 'find-file-hook
          (lambda ()
            (when (and (buffer-file-name)
                       (member (file-name-extension (buffer-file-name))
                               my-rime-extensions)
                       (not current-input-method))
              (require 'rime)
              (activate-input-method "rime"))))

(provide 'writing)
