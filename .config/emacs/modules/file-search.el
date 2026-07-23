;;; file-search.el — 文件搜索与文件操作
;;; 从 Spacemacs 移植：文件查找、最近文件、文件操作功能

;; ============================================================
;; Vertico — 增强补全菜单（提供类似 Spacemacs 的候选列表）
;; ============================================================
(use-package vertico
  :ensure t
  :init
  (vertico-mode 1))

;; ============================================================
;; Orderless — 模糊匹配（输入空格分割的关键词即可筛选）
;; ============================================================
(use-package orderless
  :ensure t
  :init
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

;; ============================================================
;; Consult — 增强的查找命令（recentf、locate、grep 等）
;; ============================================================
(use-package consult
  :ensure t
  :defer t)

;; ============================================================
;; 最近文件 (built-in)
;; ============================================================
(use-package recentf
  :ensure nil
  :init
  (setq recentf-max-saved-items 300
        recentf-exclude '("~/.config/emacs/elpa/" "/ssh:" "/sudo:"))
  :config
  (recentf-mode 1))

;; ============================================================
;; 大文件检查 (从 Spacemacs 移植)
;; ============================================================
(defvar my-large-file-size 1
  "超过此大小（MB）的文件打开时提示进入 fundamental mode。")

(defvar my-large-file-modes-list
  '(archive-mode tar-mode jka-compr git-commit-mode
                 image-mode docview-mode doc-view-mode
                 ebrowse-tree-mode pdf-view-mode)
  "大文件不提示的 major mode 列表。")

(defun my/check-large-file ()
  "打开大文件时提示是否以只读 fundamental mode 打开。"
  (let* ((filename (buffer-file-name))
         (size (and filename (nth 7 (file-attributes filename)))))
    (when (and size
               (not (memq major-mode my-large-file-modes-list))
               (> size (* 1024 1024 my-large-file-size))
               (y-or-n-p
                (format "%s 是大文件，是否以只读方式打开？" filename)))
      (setq buffer-read-only t)
      (buffer-disable-undo)
      (fundamental-mode))))
(add-hook 'find-file-hook #'my/check-large-file)

;; ============================================================
;; 文件操作函数 (从 Spacemacs 移植)
;; ============================================================

(defun my/sudo-edit (&optional arg)
  "以 sudo 权限打开当前文件或指定文件。
前缀参数 ARG 时始终提示文件路径。"
  (interactive "P")
  (require 'tramp)
  (let ((fname (if (or arg (not buffer-file-name))
                   (read-file-name "File: ")
                 buffer-file-name)))
    (find-file
     (if (not (tramp-tramp-file-p fname))
         (concat "/sudo:root@localhost:" fname)
       fname))))

(defun my/delete-current-buffer-file (&optional arg)
  "删除当前关联文件并杀掉缓冲区。
前缀参数 ARG 非空时跳过确认。"
  (interactive "P")
  (let ((filename (buffer-file-name))
        (buffer (current-buffer))
        (name (buffer-name)))
    (if (not (and filename (file-exists-p filename)))
        (kill-buffer buffer)
      (if (or arg (yes-or-no-p (format "确定删除文件 '%s' 吗？" name)))
          (progn
            (delete-file filename t)
            (kill-buffer buffer)
            (when (and (bound-and-true-p projectile-mode)
                       (projectile-project-p))
              (projectile-invalidate-cache))
            (message "文件已删除: %s" filename))
        (message "取消删除")))))

(defun my/rename-current-buffer-file (&optional arg)
  "重命名当前文件。
若缓冲区不关联文件，则提示保存或仅重命名缓冲区。
前缀参数 ARG 时提示从当前目录开始。"
  (interactive "P")
  (if-let* ((old-filename (buffer-file-name))
            ((file-exists-p old-filename)))
      (let* ((old-short (file-name-nondirectory old-filename))
             (old-dir (file-name-directory old-filename))
             (new-name (read-file-name "新名称: " (if arg old-dir old-filename)))
             (new-name (if (string= (file-name-nondirectory new-name) "")
                           (concat new-name old-short)
                         new-name))
             (new-dir (file-name-directory new-name))
             (new-short (file-name-nondirectory new-name))
             (file-moved-p (not (string-equal new-dir old-dir)))
             (file-renamed-p (not (string-equal new-short old-short))))
        (cond ((get-buffer new-name)
               (error "名为 '%s' 的缓冲区已存在！" new-name))
              ((string-equal new-name old-filename)
               (message "名称相同，未更改"))
              (t
               (when (and (not (file-exists-p new-dir))
                          (yes-or-no-p (format "创建目录 '%s' 吗？" new-dir)))
                 (make-directory new-dir t))
               (rename-file old-filename new-name 1)
               (rename-buffer new-name)
               (set-visited-file-name new-name)
               (set-buffer-modified-p nil)
               (when (bound-and-true-p recentf-mode)
                 (recentf-add-file new-name)
                 (recentf-remove-if-non-kept old-filename))
               (when (and (bound-and-true-p projectile-mode)
                          (projectile-project-p))
                 (projectile-invalidate-cache))
               (message (cond ((and file-moved-p file-renamed-p)
                               (format "文件已移动并重命名:\n从: %s\n到: %s"
                                       old-filename new-name))
                              (file-moved-p
                               (format "文件已移动:\n从: %s\n到: %s"
                                       old-filename new-name))
                              (file-renamed-p
                               (format "文件已重命名:\n%s → %s"
                                       old-short new-short)))))))
    ;; 缓冲区无关联文件
    (let ((key (read-key "缓冲区未关联文件: [s]保存到文件 或 [r]重命名缓冲区? ")))
      (pcase key
        (?s (unless (buffer-modified-p) (set-buffer-modified-p t))
            (save-buffer))
        (?r (let ((new-name (read-string "新缓冲区名称: " (buffer-name))))
              (rename-buffer new-name)))
        ((or ?\a ?\e) (keyboard-quit))))))

(defun my/save-as (filename)
  "将当前缓冲区或选中区域另存为 FILENAME。"
  (interactive (list (read-file-name "另存为: ")))
  (let ((dir (file-name-directory filename)))
    (unless (file-directory-p dir)
      (make-directory dir t)))
  (if (use-region-p)
      (write-region (region-beginning) (region-end) filename)
    (write-region nil nil filename))
  (when (y-or-n-p "是否打开保存的文件？")
    (find-file filename)))

;; ============================================================
;; 复制路径函数 (从 Spacemacs 移植)
;; ============================================================

(defun my/copy-file-path ()
  "复制当前文件的完整路径到剪贴板。"
  (interactive)
  (if-let* ((file-path (buffer-file-name)))
      (let ((path (file-truename file-path)))
        (kill-new path)
        (message "%s" path))
    (user-error "当前缓冲区未关联文件")))

(defun my/copy-file-name ()
  "复制当前文件名到剪贴板。"
  (interactive)
  (if-let* ((file-name (and (buffer-file-name)
                            (file-name-nondirectory (buffer-file-name)))))
      (progn
        (kill-new file-name)
        (message "%s" file-name))
    (user-error "当前缓冲区未关联文件")))

(defun my/copy-file-name-base ()
  "复制当前文件名（不含扩展名）到剪贴板。"
  (interactive)
  (if-let* ((name (file-name-base (buffer-file-name))))
      (progn
        (kill-new name)
        (message "%s" name))
    (user-error "当前缓冲区未关联文件")))

(defun my/copy-directory-path ()
  "复制当前目录路径到剪贴板。"
  (interactive)
  (kill-new default-directory)
  (message "%s" default-directory))

(defun my/copy-file-path-with-line ()
  "复制文件路径+行号到剪贴板。"
  (interactive)
  (if-let* ((file-path (buffer-file-name)))
      (let ((path (format "%s:%d" (file-truename file-path) (line-number-at-pos))))
        (kill-new path)
        (message "%s" path))
    (user-error "当前缓冲区未关联文件")))

;; ============================================================
;; 外部程序打开 (从 Spacemacs 移植)
;; ============================================================

(defun my/open-in-external-app (&optional arg)
  "在外部程序中打开当前文件。
前缀参数 ARG 时打开所在文件夹。"
  (interactive "P")
  (let ((path (if arg
                  default-directory
                (or (and (derived-mode-p 'dired-mode)
                         (dired-get-file-for-visit))
                    buffer-file-name))))
    (if path
        (pcase system-type
          ('darwin (shell-command (format "open \"%s\"" path)))
          ('linux (let ((process-connection-type nil))
                    (start-process "" nil "xdg-open" path)))
          ('windows-nt (w32-shell-execute "open" path)))
      (message "当前缓冲区未关联文件"))))

(provide 'file-search)
