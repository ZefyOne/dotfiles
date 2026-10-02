;;; ui.el -*- lexical-binding: t; -*-

;; ============================================================
;; M-x界面
;; ============================================================
(custom-set-faces!                                                              ; 在M-x中光标行的颜色，淡蓝
  '(vertico-current :background "#ADD8E6" :extend t))

(custom-set-faces!                                                              ; v模式下选中区域的背景色，取出主题的 eg-purple3
  '(region :background "#D8CAD4" :foreground "#4C4741" :extend t))              ; 想更淡一点可以用 "#CDCBC7"（eg-grey3）

(after! vertico-posframe                                                        ; M-x / 补全候选浮到屏幕中间（vertico-posframe）
  (setq vertico-posframe-poshandler #'posframe-poshandler-frame-center))


;; ============================================================
;; 字体配置
;; ============================================================
(setq doom-font (font-spec :family "Fira Code" :size 25 :weight 'medium)
      doom-variable-pitch-font (font-spec :family "Noto Sans CJK SC" :size 25)) ; 设置主要字体，英文和符号是fira code，再加一个兜底

(set-fontset-font t 'han (font-spec :family "LXGW WenKai Mono"))                ; 设置中文字体为霞鹜文楷等宽，一个比较知名的楷体，这里面不能用size

(set-fontset-font t 'cjk-misc (font-spec :family "LXGW WenKai Mono"))           ; 解决中文标点垂直居中的问题，加上就正常了



;; 设置行间距，三种特定文件下，行间距为0.6倍
;; 写成 cons 把间距全部放到文字「上方」：行与行之间的视觉间距不变，
;; 但 hbar 光标（贴行底）就不会掉进行距里，行尾也不会变高。
;; 注意 cons 两边类型必须一致，写成 (0.6 . 0) 会被当成非法值、行距直接变 0
;;
;; :depth -10 是为了抢在 novel.el 那个 hook 之前跑（Doom 的 add-hook! 默认
;; prepend，加载顺序和作用顺序相反）。novel.el 里会开 writeroom，而 writeroom
;; 把 line-spacing 列进 writeroom--local-variables 代管：启用时记下当时的值，
;; 停用（F7）时按记录恢复 —— 记的是裸符号就 kill-local-variable。要是我们设晚
;; 了，它记的就是裸符号，F7 一关就把这份局部行距清掉，且不会自己回来。
(add-hook! (org-mode markdown-mode novel-mode) :depth -10
  (setq-local line-spacing '(0.6 . 0.0)))
;; (setq-default line-spacing 0.2)


;; ============================================================
;; 稿纸线（每行下方一条虚线）
;; ============================================================
(defvar ruled-lines-offset 15
  "稿纸线画在基线下方的像素数。改大往下移，改小往上移。")

;; 必须用 face-remap-add-relative 而不是 set-face-attribute：
;; 前者改的是 buffer-local 的 face-remapping-alist，只影响当前 buffer；
;; 后者全局生效，会把 mode-line、minibuffer 一起画上线。
(defvar-local ruled-lines--cookie nil
  "face-remap-add-relative 的返回值，用于撤销映射。")

(define-minor-mode ruled-lines-mode
  "给每行下面画一条虚线，像稿纸一样。"
  :lighter " 稿纸"
  (if ruled-lines-mode
      (progn
        (setq-local underline-minimum-offset ruled-lines-offset)
        (setq ruled-lines--cookie
              (face-remap-add-relative
               'default '(:underline (:style dashes :color "#9E9A95") :extend t))))
    (when ruled-lines--cookie
      (face-remap-remove-relative ruled-lines--cookie)
      (setq ruled-lines--cookie nil))
    (kill-local-variable 'underline-minimum-offset)))
