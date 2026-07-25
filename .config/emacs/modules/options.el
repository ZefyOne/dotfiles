;;; options.el — 编辑器行为设置

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

;; ============================================================
;; 编辑行为
;; ============================================================
(global-visual-line-mode 1)             ;; 软换行
(global-display-line-numbers-mode 1)    ;; 行号
(delete-selection-mode 1)               ;; 选中后打字直接替换
(save-place-mode 1)                     ;; 记住上次编辑位置
(global-auto-revert-mode 1)             ;; 文件外部变更时自动刷新
(show-paren-mode 1)                     ;; 高亮匹配括号
(column-number-mode 1)                  ;; mode line 显示列号

;; ============================================================
;; 缩进与填充
;; ============================================================
(setq-default fill-column 80)
(setq sentence-end-double-space nil)    ;; 句号后一个空格即可
(setq-default indent-tabs-mode nil      ;; 不用 tab，用空格
               tab-width 4
               standard-indent 4)

;; ============================================================
;; 持久化 Undo（退出重开后仍可撤销）
;; ============================================================
(use-package undo-fu-session
  :ensure t
  :config
  (global-undo-fu-session-mode 1))

;; ============================================================
;; 补全忽略大小写
;; ============================================================
(setq read-file-name-completion-ignore-case t
      read-buffer-completion-ignore-case t)

;; ============================================================
;; 外观
;; ============================================================


;; ============================================================
;; 杂项
;; ============================================================
(setq ring-bell-function 'ignore)       ;; 关闭提示音

(provide 'options)

