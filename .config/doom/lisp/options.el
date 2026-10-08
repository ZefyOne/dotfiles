;;; .config/doom/lisp/options.el -*- lexical-binding: t; -*-


;; ============================================================
;; options属性
;; ============================================================
(setq display-line-numbers-type t)            ; 行号样式，nil关闭行号，relative相对行号
(after! evil (setq evil-insert-state-cursor '(hbar . 2)))  ; 插入态横线光标：只按行底定位，不受 line-spacing 影响（bar/box 都会被撑长）
(remove-hook 'doom-first-input-hook #'global-hl-line-mode)  ; 关闭光标行高亮

;; ============================================================
;; 滚动
;; ============================================================
;; 光标离窗口上/下边缘保留的屏幕行数，一到这个距离就自动滚动。Doom 核心默认
;; 设的是 0（doom-emacs.el:664），config.el 在其之后加载，裸 setq 就能覆盖。
;; 两点注意：
;;   1. 上下对称生效 —— Emacs 没有「只保留下边」的选项，顶边也会留同样行数。
;;   2. 有效值会被裁剪：maximum-scroll-margin 默认 0.25，上限是窗口高度的
;;      1/4（且不超过 (窗口行数-1)/2）。窗口 24 行时写 10 其实只有 6。
;; 与 Doom 已设的 scroll-conservatively 10 配合：光标进到边距内时最多滚 10 行
;; 把它弄回屏幕，滚不回来才 recenter 到中间，所以 3~8 用起来都平顺；
;; 若想设到 10 以上，得同时把 scroll-conservatively 提到 100 以上（永不 recenter）。
(setq scroll-margin 8)

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
