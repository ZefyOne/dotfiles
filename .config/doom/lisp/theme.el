;;; .config/doom/lisp/theme.el -*- lexical-binding: t; -*-


;; ============================================================
;; 主题配置
;; ============================================================

;; 加载主题有两种方式，前提都是主题已安装且可用。你可以设置 `doom-theme'，
;; 也可以用 `load-theme' 函数手动加载主题。下面是默认配置：

;; 也可以像下面这样同时指定暗色和亮色主题，Doom 会根据系统的明暗设置
;; 决定加载哪一个：
;;
;;   (setq doom-theme '(doom-one   . doom-one-light))   ; (暗色 . 亮色)
;;
;; 如果你想根据系统明暗模式更主动地切换主题，可以去了解 `auto-dark' 包。




; (setq doom-theme 'doom-one)
;; (setq doom-theme 'doom-flatwhite)
;; (setq doom-theme 'doom-dracula)
;; (setq doom-theme 'doom-earl-grey)      ;; 淡白色主题
;; (setq doom-theme 'poet)                ;; 原来的米色主题，想换回去就取消注释

(setq doom-theme 'everforest-hard-light)


;; ============================================================
;; 标签栏跟随主题
;; ============================================================
;; centaur-tabs(Doom 的 :ui tabs 模块)渲染在内置的 `tab-line' face 上,
;; 而几乎没有主题会覆盖它 —— 于是换主题后标签栏一直露出 Emacs 默认的
;; grey85,跟主题底色打架(poet 的米色底尤其明显)。
;;
;; 下面这个钩子让标签栏底色跟着当前主题的 `default' 背景走:亮底压暗一档、
;; 暗底提亮一档,和编辑区拉开一点层次。以后换任何主题都自动跟随,不用再改。

(require 'color)

(defun my/--mix (c1 c2 amount)
  "在颜色 C1 与 C2 之间线性插值。AMOUNT 为 0 取 C1,为 1 取 C2。"
  (let ((a (color-name-to-rgb c1))
        (b (color-name-to-rgb c2)))
    (when (and a b)
      (let ((at (lambda (i) (+ (* (nth i a) (- 1 amount))
                               (* (nth i b) amount)))))
        ;; 末位参数 2 表示每通道 2 位十六进制,得到常见的 #rrggbb
        (color-rgb-to-hex (funcall at 0) (funcall at 1) (funcall at 2) 2)))))

(defun my/tab-line-follow-theme (&rest _)
  "让标签栏(`tab-line')跟随当前主题的配色。

centaur-tabs 渲染在内置的 `tab-line' face 上,而几乎没主题会覆盖它,于是
换主题后标签栏会一直露出 Emacs 默认的 grey85。这里按当前主题 `default' 的
前景/背景现算一套协调色,换任何主题都自动跟随。"
  (when (facep 'tab-line)
    (let ((bg (face-attribute 'default :background nil t))
          (fg (face-attribute 'default :foreground nil t)))
      (when (and (stringp bg) (stringp fg)
                 (color-name-to-rgb bg) (color-name-to-rgb fg))
        (let* ((dark-p (< (apply #'+ (color-name-to-rgb bg)) 1.5))
               (toward (if dark-p "#ffffff" "#000000"))
               (bar    (my/--mix bg toward 0.06))  ; 标签栏底:比编辑区深/亮一档
               (sel    (my/--mix fg bg 0.35))      ; 当前标签的文字
               (dim    (my/--mix fg bg 0.45))      ; 其余标签的文字,淡一些
               (mark   (my/--mix fg bg 0.15)))     ; 修改标记,比名字实一点才看得见
          (set-face-attribute 'tab-line nil :background bar :foreground dim)
          ;; centaur-tabs 自己那套 face 也得跟上,否则修改标记、关闭按钮会一直
          ;; 用包里写死的深色(#31343E / #3D3C3D),和主题底色打架。
          (dolist (spec `((centaur-tabs-default                    (:background ,bar :foreground ,dim))
                          (centaur-tabs-unselected                 (:background ,bar :foreground ,dim))
                          (centaur-tabs-unselected-modified        (:background ,bar :foreground ,dim))
                          (centaur-tabs-selected                   (:background ,bar :foreground ,sel :weight bold))
                          (centaur-tabs-selected-modified          (:background ,bar :foreground ,sel :weight bold))
                          (centaur-tabs-modified-marker-selected   (:background ,bar :foreground ,mark))
                          (centaur-tabs-modified-marker-unselected (:background ,bar :foreground ,dim))
                          (centaur-tabs-close-selected             (:background ,bar :foreground ,sel))
                          (centaur-tabs-close-unselected           (:background ,bar :foreground ,dim))))
            (when (facep (car spec))
              (apply #'set-face-attribute (car spec) nil (cadr spec)))))))))

(add-hook 'enable-theme-functions #'my/tab-line-follow-theme)
(with-eval-after-load 'centaur-tabs (my/tab-line-follow-theme))
(my/tab-line-follow-theme)  ; 让当前这次也立即生效
