;;; keymaps.el — 所有快捷键绑定
;;; 每条带中文注释说明功能

;; ============================================================
;; 全局快捷键
;; ============================================================

(global-set-key (kbd "C-e")                'end-of-line)
;;   ^^ C-e 到逻辑行尾（无视 visual-line-mode 软换行）

(global-set-key (kbd "C-c C-n")            'tab-line-switch-to-next-tab)
;;   ^^ C-c C-n 标签栏：下一个标签

(global-set-key (kbd "C-c C-p")            'tab-line-switch-to-prev-tab)
;;   ^^ C-c C-p 标签栏：上一个标签

(global-set-key (kbd "<f2>")               (lambda () (interactive)
                                             (find-file "~/.config/emacs/init.el")))
;;   ^^ F2 快速打开 init.el

(global-set-key (kbd "<f7>")               'olivetti-mode)
;;   ^^ F7 切换专注模式 (olivetti)

(global-set-key (kbd "C-\\")               'toggle-input-method)
;;   ^^ C-\ 切换输入法 (rime)

;; ============================================================
;; Evil Normal 状态快捷键
;; ============================================================

(define-key evil-normal-state-map (kbd "H")     'tab-line-switch-to-prev-tab)
;;   ^^ H 标签栏：上一个标签

(define-key evil-normal-state-map (kbd "L")     'tab-line-switch-to-next-tab)
;;   ^^ L 标签栏：下一个标签

(define-key evil-normal-state-map (kbd "C-u")   'evil-scroll-up)
;;   ^^ C-u 向上翻屏

(define-key evil-normal-state-map (kbd "j")     'evil-next-visual-line)
;;   ^^ j 向下移动（按视觉行，折行时逐屏走）

(define-key evil-normal-state-map (kbd "k")     'evil-previous-visual-line)
;;   ^^ k 向上移动（按视觉行）

(define-key evil-normal-state-map (kbd "C-r")   'evil-redo)
;;   ^^ C-r 重做

(define-key evil-normal-state-map (kbd "C-e")   'end-of-line)
;;   ^^ C-e 到逻辑行尾

;; ============================================================
;; Evil Insert 状态快捷键
;; ============================================================

(define-key evil-insert-state-map (kbd "C-e")   'end-of-line)
;;   ^^ C-e 到逻辑行尾

(define-key evil-insert-state-map (kbd "C-l")   'delete-char)
;;   ^^ C-l 删除光标处字符（右删除）

(define-key evil-insert-state-map (kbd "C-a")   'beginning-of-line)
;;   ^^ C-a 到行首

(define-key evil-insert-state-map (kbd "C-p")   'previous-line)
;;   ^^ C-p 上一行

(define-key evil-insert-state-map (kbd "C-n")   'next-line)
;;   ^^ C-n 下一行

(define-key evil-insert-state-map (kbd "C-u")
  (lambda () (interactive)
    (kill-line 0)))
;;   ^^ C-u 删除光标到行首

(define-key evil-insert-state-map (kbd "C-k")
  (lambda () (interactive)
    (let ((end (save-excursion (end-of-line) (point))))
      (when (> end (point))
        (kill-region (point) end)))))
;;   ^^ C-k 删除光标到逻辑行尾（无视 visual-line-mode 软换行）

(provide 'keymaps)
