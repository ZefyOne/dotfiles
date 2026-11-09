;;; my-markdown.el -*- lexical-binding: t; -*-

;; ============================================================
;; j / k 按视觉行移动
;; ============================================================
;; evil 默认的 j/k 按逻辑行走，这里换成 visual-line 版本，与 my-org.el 里的
;; evil-org 处理保持一致。visual-line-mode 由 Doom 给 text 派生模式自动开启。
(after! evil-markdown
  (evil-define-key '(normal motion visual) evil-markdown-mode-map
    "j" #'evil-next-visual-line
    "k" #'evil-previous-visual-line))
