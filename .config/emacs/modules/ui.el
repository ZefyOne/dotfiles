;;; ui.el — 界面与外观

;; ============================================================
;; 字体
;; ============================================================
(set-face-attribute 'default nil
                    :family "Noto Sans Mono CJK SC"
                    :height 190
                    :weight 'normal)

(setq-default line-spacing nil)

;; ============================================================
;; 窗口
;; ============================================================
(setq default-frame-alist
      '((width . 100)
        (height . 35)))

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
;; 去干扰
;; ============================================================
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-screen t
      initial-scratch-message nil)

;; ============================================================
;; 光标
;; ============================================================
(setq x-stretch-cursor nil)
(add-hook 'window-setup-hook
          (lambda ()
            (set-frame-parameter nil 'cursor-type 'hbar)
            (set-default 'cursor-type '(hbar . 2))))

;; ============================================================
;; 高亮当前行
;; ============================================================
(global-hl-line-mode 1)

;; ============================================================
;; 标签栏
;; ============================================================
(global-tab-line-mode 1)

;; ============================================================
;; 主题 (doom-themes)
;; ============================================================
(use-package doom-themes
  :ensure t
  :config
  ;; 使用 doom-one，可换成你喜欢的
  (load-theme 'doom-one t)
  ;; 更丰富的语法高亮（org-mode 等）
  (doom-themes-org-config))

;; ============================================================
;; 文件管理器 (dirvish)
;; ============================================================
(use-package dirvish
  :ensure t
  :config
  (dirvish-override-dired-mode)
  (setq dirvish-mode-line-height 18
        dirvish-hide-details t
        dirvish-use-header-line t
        dirvish-reuse-session nil))

(provide 'ui)
