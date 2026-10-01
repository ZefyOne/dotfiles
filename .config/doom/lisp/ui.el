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




;; Doom 提供五个（可选的）变量来控制字体：
;;
;; - `doom-font' -- 使用的主字体
;; - `doom-variable-pitch-font' -- 非等宽字体（在适用的场景下）
;; - `doom-big-font' -- 供 `doom-big-font-mode' 使用；适合做演示或直播时用
;; - `doom-symbol-font' -- 用于符号
;; - `doom-serif-font' -- 用于 `fixed-pitch-serif' face
;;
;; 用 'C-h v doom-font' 查看文档以及更多可接受取值的示例。例如：
;;
;; (setq doom-font (font-spec :family "Fira Code" :size 21 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; 如果你或 Emacs 找不到字体，可以用 'M-x describe-font' 查一下，
;; 用 `M-x eval-region' 执行 elisp 代码，用 'M-x doom/reload-font' 刷新字体设置。
;; 如果 Emacs 还是找不到字体，那多半是字体没装好。字体问题很少是 Doom 的问题！


;; ============================================================
;; 行间距
;; ============================================================
;; 注意这不是行高：行高由上面 doom-font 的 :size 决定，
;; 这里控制的是行与行之间额外插入的空白。

;; 取值形式：
;;   浮点  0.2          → 相对行高的比例，跟着字号缩放
;;   整数  4            → 绝对像素，加在每行下方
;;   cons  '(0.1 . 0.1) → 分别指定行上方 / 下方的空间
;;
;; line-spacing 是 buffer-local 变量，所以必须用 setq-default 才全局生效。
;; 另外它只在图形界面生效，终端里跑 `emacs -nw' 不会有变化。
;;
;; 想只给正文加行距、代码模式保持紧凑，就删掉下面这行改成：
(add-hook! (org-mode markdown-mode text-mode) (setq-local line-spacing 0.6))
;; (setq-default line-spacing 0.2)


;; ============================================================
;; 稿纸线（每行下方一条虚线）
;; ============================================================
;; 用 M-x ruled-lines-mode 手动开关。
;;
;; 两个要素：
;;   :style dashes  → 虚线样式，也可换 line / dots / wave
;;   :extend t      → 让线延伸到窗口右边缘，横贯整行；
;;                    去掉就只有文字底下有线段
;;
;; 线的垂直位置由 underline-minimum-offset 控制（基线下方多少像素），
;; 这个值必须是 buffer-local 设置的，1:1 对应像素。
;;
;; 颜色取了 doom-earl-grey 自带的 shadow 色，比中性灰更贴合暖色调。
;; 由浅到深： #c8c8c8（中性灰）→ #AEABA6（主题 fringe）
;;           → #9E9A95（主题 shadow，当前）→ #7A756D（接近正文字色）
;;
;; 不要动 x-underline-at-descent-line。它会把线推到行的最底部，
;; 并且额外叠加 line-spacing 的像素 —— 文档里那句 "moves the underline
;; lower by that many pixels" 是真的。后果是虚线紧贴下一行文字的顶部，
;; 看着离上一行很远、离下一行很近。保持默认 nil 即可。

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
