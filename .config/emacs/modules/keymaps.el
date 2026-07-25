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
;;   ^^ F7 切换码字专注模式 (olivetti)

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

(define-key evil-normal-state-map [escape]      'keyboard-quit)
;;   ^^ ESC 在 n 模式也触发 C-g（取消选中、取消 minibuffer 等）




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

(define-key evil-insert-state-map (kbd "C-j")   'newline)
;;   ^^ C-j 换行，不自动缩进

(define-key evil-insert-state-map (kbd "C-h")   'delete-backward-char)
;;   ^^ C-h 删除前一个字符（i 模式专用，n 模式不变）

(define-key evil-insert-state-map (kbd "C-y")   'yank)
;;   ^^ C-y 粘贴（从 kill ring 恢复）

(define-key evil-insert-state-map (kbd "C-o")   'open-line)
;;   ^^ C-o 插入新行并保持光标不动（i 模式专用）




;; ============================================================
;; Leader 键 (SPC) — 前缀定义
;; ============================================================

(define-key evil-normal-state-map (kbd "SPC") nil)

(define-prefix-command 'my-leader-map)
(define-key evil-normal-state-map (kbd "SPC") my-leader-map)





;; ============================================================
;; SPC e — 文件树
;; ============================================================

(define-key my-leader-map (kbd "e") 'my/treemacs)
;;   ^^ SPC e 打开 treemacs 文件树

(define-key my-leader-map (kbd "E") 'treemacs-find-file)
;;   ^^ SPC E 在文件树中定位当前文件




;; ============================================================
;; SPC p — 项目管理
;; ============================================================

(define-prefix-command 'my-project-prefix-map)
(define-key my-leader-map (kbd "p") my-project-prefix-map)

(define-key my-project-prefix-map (kbd "t") 'my/treemacs-project-toggle)
;;   ^^ SPC p t 在项目根打开/切换 treemacs
(define-key my-project-prefix-map (kbd "f") 'projectile-find-file)
;;   ^^ SPC p f 项目内查找文件
(define-key my-project-prefix-map (kbd "p") 'projectile-switch-project)
;;   ^^ SPC p p 切换项目
(define-key my-project-prefix-map (kbd "b") 'projectile-switch-to-buffer)
;;   ^^ SPC p b 项目内切换缓冲区
(define-key my-project-prefix-map (kbd "d") 'projectile-find-dir)
;;   ^^ SPC p d 项目内查找目录
(define-key my-project-prefix-map (kbd "r") 'projectile-recentf)
;;   ^^ SPC p r 项目内最近文件
(define-key my-project-prefix-map (kbd "R") 'projectile-replace)
;;   ^^ SPC p R 项目内文本替换
(define-key my-project-prefix-map (kbd "D") 'projectile-dired)
;;   ^^ SPC p D 项目根打开 dired

;; 在 treemacs 状态下也支持 SPC 快捷键
(with-eval-after-load 'treemacs-evil
  (define-key evil-treemacs-state-map (kbd "SPC") my-leader-map))




;; ============================================================
;; SPC f — 文件查找与操作
;; ============================================================

(define-key my-leader-map (kbd "SPC") 'fzf-find-file)
;;   ^^ SPC SPC 搜索文件（fzf 引擎，递归 + 隐藏文件）

(define-prefix-command 'my-file-prefix-map)
(put 'my-file-prefix-map 'which-key-description "Files")
(define-key my-leader-map (kbd "f") my-file-prefix-map)

(define-key my-file-prefix-map (kbd "r") 'consult-recent-file)
;;   ^^ SPC f r 最近打开的文件
(define-key my-file-prefix-map (kbd "L") 'consult-locate)
;;   ^^ SPC f L 用 locate 搜索文件
(define-key my-file-prefix-map (kbd "l") 'find-file-literally)
;;   ^^ SPC f l 以字面方式打开（不启用 major mode）
(define-key my-file-prefix-map (kbd "i") 'insert-file)
;;   ^^ SPC f i 插入文件内容到当前缓冲区

;; 保存
(define-key my-file-prefix-map (kbd "s") 'save-buffer)
;;   ^^ SPC f s 保存
(define-key my-file-prefix-map (kbd "S") 'evil-write-all)
;;   ^^ SPC f S 保存所有缓冲区

;; 操作
(define-key my-file-prefix-map (kbd "c") 'my/save-as)
;;   ^^ SPC f c 另存为
(define-key my-file-prefix-map (kbd "R") 'my/rename-current-buffer-file)
;;   ^^ SPC f R 重命名
(define-key my-file-prefix-map (kbd "d") 'my/delete-current-buffer-file)
;;   ^^ SPC f d 删除（需确认）
(define-key my-file-prefix-map (kbd "D") 'my/delete-current-buffer-file-yes)
;;   ^^ SPC f D 直接删除（不确认）
(define-key my-file-prefix-map (kbd "E") 'my/sudo-edit)
;;   ^^ SPC f E 用 sudo 编辑
(define-key my-file-prefix-map (kbd "o") 'my/open-in-external-app)
;;   ^^ SPC f o 在外部程序打开

;; SPC f y — 复制路径
(define-prefix-command 'my-file-yank-prefix-map)
(put 'my-file-yank-prefix-map 'which-key-description "Yank/Copy")
(define-key my-file-prefix-map (kbd "y") my-file-yank-prefix-map)

(define-key my-file-yank-prefix-map (kbd "y") 'my/copy-file-path)
;;   ^^ SPC f y y 复制文件完整路径
(define-key my-file-yank-prefix-map (kbd "n") 'my/copy-file-name)
;;   ^^ SPC f y n 复制文件名
(define-key my-file-yank-prefix-map (kbd "N") 'my/copy-file-name-base)
;;   ^^ SPC f y N 复制文件名（不含扩展名）
(define-key my-file-yank-prefix-map (kbd "d") 'my/copy-directory-path)
;;   ^^ SPC f y d 复制目录路径
(define-key my-file-yank-prefix-map (kbd "l") 'my/copy-file-path-with-line)
;;   ^^ SPC f y l 复制文件路径+行号




;; ============================================================
;; SPC a — 应用程序
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

;; ============================================================
;; SPC t — 主题浏览（光标移动即时切换）
;; ============================================================

(define-prefix-command 'my-theme-prefix-map)
(put 'my-theme-prefix-map 'which-key-description "Theme")
(define-key my-leader-map (kbd "t") my-theme-prefix-map)

(defvar my/theme-preview-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "j") 'next-line)
    (define-key map (kbd "k") 'previous-line)
    (define-key map (kbd "q") 'kill-this-buffer)
    map)
  "Theme preview mode keymap.")

(define-minor-mode my/theme-preview-mode
  "上下移动光标即时切换主题，q 退出。"
  :keymap my/theme-preview-mode-map
  (if my/theme-preview-mode
      (add-hook 'post-command-hook #'my/theme-preview--at-point nil t)
    (remove-hook 'post-command-hook #'my/theme-preview--at-point t)
    (when (get-buffer "*Themes*")
      (kill-buffer "*Themes*"))))

(defun my/theme-preview--at-point ()
  "加载光标所在行的主题。"
  (when-let* ((theme (get-text-property (point) 'theme)))
    (ignore-errors (load-theme theme t))))

(defun my/browse-themes ()
  "打开主题浏览缓冲区，上下移动光标即时切换。"
  (interactive)
  (let* ((themes (custom-available-themes))
         (buf (get-buffer-create "*Themes*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (dolist (theme (sort themes #'string<))
          (insert (propertize (format "%s\n" theme) 'theme theme)))
        (goto-char (point-min))
        (my/theme-preview-mode)
        (setq-local cursor-type nil
                    buffer-read-only t)))
    (display-buffer buf)
    (my/theme-preview--at-point)))

(define-key my-theme-prefix-map (kbd "b") 'my/browse-themes)
;;   ^^ SPC t b 打开主题浏览器

(provide 'keymaps)
