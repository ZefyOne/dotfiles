;;; .config/doom/lisp/options.el -*- lexical-binding: t; -*-


;; ============================================================
;; options属性
;; ============================================================
(setq display-line-numbers-type t)            ; 行号样式，nil关闭行号，relative相对行号
(setq evil-insert-state-cursor '(hbar . 2))   ; 横线光标


;; ============================================================
;; 中文软换行
;; ============================================================
;; Doom 核心默认 (setq-default word-wrap t)，即「只在空格处断行」
;; （doom-emacs.el:546）。中文没有空格可断，Emacs 在右边界附近找不到断点，
;; 就一路退回行内最后一个空格处断开 —— 那一行剩下的大片区域全空着，正文被
;; 推到下一显示行，看着像是「把原本那行空出来了」。
;; 打开 word-wrap-by-category 后 CJK 字符之间也成为合法断点，行能填满，且
;; 英文单词仍然不会被从中间劈开。
;; 注：这个变量用 Customize 设置时 Emacs 会自动加载 kinsoku，用 setq 不会，
;; 所以下面显式 require；加载后软换行才会遵守禁则（，。等标点不落行首）。
(require 'kinsoku)                            ; 禁则处理
(setq-default word-wrap-by-category t)        ; 允许在 CJK 字符间断行
