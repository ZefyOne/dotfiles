;;; init.el — 写作向 Emacs 配置

;; ============================================================
;; 编码
;; ============================================================
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8-unix)
(set-terminal-coding-system 'utf-8-unix)
(set-keyboard-coding-system 'utf-8-unix)
(set-selection-coding-system 'utf-8-unix)
(setq locale-coding-system 'utf-8-unix)
(setq file-name-coding-system 'utf-8-unix)
(prefer-coding-system 'utf-8-unix)

;; 自定义设置存到 XDG 目录，远离 ~/.emacs.d
(setq custom-file "~/.config/emacs/custom.el")
(load custom-file t)

;; 确保默认字体不受之前 session 残留设置影响
(set-face-attribute 'default nil
                    :family "Noto Sans Mono CJK SC"
                    :height 190
                    :weight 'normal)     ; 加宽字间距

(setq-default line-spacing nil)             ; 无额外行间距

;; ============================================================
;; 包管理
;; ============================================================
(require 'package)
(setq package-user-dir "~/.config/emacs/elpa")    ; 包安装目录，远离 ~/.emacs.d
(setq package-archives '(("gnu"   . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
                         ("melpa" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")))
(package-initialize)

;; ============================================================
;; 界面 — 消除干扰
;; ============================================================
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-screen t
      initial-scratch-message nil)

;; ============================================================
;; 编辑器行为
;; ============================================================
(global-visual-line-mode 1)          ; 软换行，不插入实际换行符
(global-display-line-numbers-mode 1) ; 显示行号
(global-set-key (kbd "C-e") 'end-of-line)    ; C-e 走逻辑行尾而非视觉行尾
(delete-selection-mode 1)            ; 选中后打字直接替换
(save-place-mode 1)                  ; 记住上次编辑位置
(global-auto-revert-mode 1)          ; 文件外部变更时自动刷新
(setq-default fill-column 80)        ; 默认填充列宽

;; 中文引号自动配对
(setq electric-pair-pairs
      '((?\" . ?\")
        (?「 . ?」)
        (?' . ?')
        (?【 . ?】)
        (?《 . ?》)))
(electric-pair-mode 1)

;; ============================================================
;; 备份与自动保存
;; ============================================================
(unless (file-exists-p "~/.config/emacs/backups/")
  (make-directory "~/.config/emacs/backups/" t))   ; 确保备份目录存在
(setq backup-directory-alist '(("." . "~/.config/emacs/backups/"))
      auto-save-file-name-transforms '((".*" "~/.config/emacs/backups/" t))
      auto-save-list-file-prefix "~/.config/emacs/backups/sessions-")

(setq auto-save-timeout 120          ; 空闲 2 分钟后自动保存
      auto-save-interval 300)        ; 或输入 300 个字符后保存

;; ============================================================
;; 字数统计
;; ============================================================
(defun writing--count-non-space (begin end)
  "计算区域内的非空白字符数（标点也算，空白不算）。"
  (- (- end begin)
     (how-many "[[:space:]]" begin end)))

;; 在默认 mode-line-format 追加编码和字数
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
  :bind ("<f7>" . olivetti-mode)
  :config
  (setq olivetti-body-width 80        ; 约 40 个中文字符宽
        olivetti-minimum-body-width 60
        olivetti-recall-visual-line-mode-entry-state t))

;; ============================================================
;; 外观
;; ============================================================
(setq default-frame-alist
      '((width . 100)      ; 窗口宽 100 字符
        (height . 35)))    ; 窗口高 35 行

(defun center-frame-callback ()
  "将窗口居中。"
  (interactive)
  (let* ((frame (selected-frame))
         (fw (* 100 (frame-char-width frame)))
         (fh (* 35 (frame-char-height frame)))
         (sw (display-pixel-width))
         (sh (display-pixel-height)))
    (set-frame-position frame
                        (/ (- sw fw) 2)
                        (/ (- sh fh) 2))))
(add-hook 'window-setup-hook #'center-frame-callback)

;; ============================================================
;; 会话恢复 — 启动时自动打开上次的文件
;; ============================================================
(desktop-save-mode 1)
(setq desktop-path '("~/.config/emacs/"))
(setq desktop-dirname "~/.config/emacs/")
(setq desktop-save t)                 ; 退出时不询问，自动保存
(setq desktop-auto-save-timeout 300)

;; 高亮当前行
(global-hl-line-mode 1)

;; ============================================================
;; 标签栏 — 浏览器风格，每个文件一个标签
;; ============================================================
(global-tab-line-mode 1)
(global-set-key (kbd "C-c C-n") 'tab-line-switch-to-next-tab)
(global-set-key (kbd "C-c C-p") 'tab-line-switch-to-prev-tab)

;; ============================================================
;; 中文输入 (rime)
;; ============================================================
(use-package rime
  :ensure t
  :custom
  (rime-user-data-dir "~/.config/emacs/rime/")
  (rime-show-candidate 'minibuffer)
  (default-input-method "rime")
  :bind
  ("C-\\" . toggle-input-method))

;; ============================================================
;; 杂项
;; ============================================================
(setq sentence-end-double-space nil)  ; 句号后一个空格即可
(setq-default indent-tabs-mode nil     ; 不用 tab，用空格
               tab-width 4               ; tab 宽度 4 字符
               standard-indent 4)        ; 默认缩进 4 空格
(show-paren-mode 1)                   ; 高亮匹配的括号
(column-number-mode 1)                ; 在 mode line 显示列号
(setq ring-bell-function 'ignore)     ; 关闭提示音
(global-set-key (kbd "C-u") (lambda () (interactive) (kill-line 0)))  ; 删光标前到行首
(setq x-stretch-cursor nil)           ; 光标仅覆盖字符区域，不延伸到行间距
;; 启动完成后设置下划线光标
(add-hook 'window-setup-hook
          (lambda ()
            (set-frame-parameter nil 'cursor-type 'hbar)
            (set-default 'cursor-type '(hbar . 2))))
(setq read-file-name-completion-ignore-case t)  ; 文件名补全忽略大小写
(setq read-buffer-completion-ignore-case t)      ; 缓冲区名补全忽略大小写
