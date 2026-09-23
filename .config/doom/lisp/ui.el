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


