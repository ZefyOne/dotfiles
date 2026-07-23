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

;; ============================================================
;; Leader 键 (SPC) — Spacemacs 风格快捷键
;; ============================================================
(define-key evil-normal-state-map (kbd "SPC") nil)

(define-prefix-command 'my-leader-map)
(define-key evil-normal-state-map (kbd "SPC") my-leader-map)

;; SPC e — 文件树
(define-key my-leader-map (kbd "e") 'my/treemacs)
(define-key my-leader-map (kbd "E") 'treemacs-find-file)

;; SPC p — 项目操作
(define-prefix-command 'my-project-prefix-map)
(define-key my-leader-map (kbd "p") my-project-prefix-map)

(define-key my-project-prefix-map (kbd "t") 'my/treemacs-project-toggle)
(define-key my-project-prefix-map (kbd "f") 'projectile-find-file)
(define-key my-project-prefix-map (kbd "p") 'projectile-switch-project)

;; 在 treemacs 状态下也支持 SPC 快捷键
(with-eval-after-load 'treemacs-evil
  (define-key evil-treemacs-state-map (kbd "SPC") my-leader-map))

;; ============================================================
;; SPC a — Applications（Spacemacs 风格）
;; ============================================================
(define-prefix-command 'my-apps-prefix-map)
(put 'my-apps-prefix-map 'which-key-description "Applications")
(define-key my-leader-map (kbd "a") my-apps-prefix-map)

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
;; Org-mode 快捷键
;; ============================================================
(with-eval-after-load 'org
  ;; Normal state 下 RET 打开链接
  (evil-define-key 'normal org-mode-map (kbd "RET") 'org-open-at-point)

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

(provide 'keymaps)
