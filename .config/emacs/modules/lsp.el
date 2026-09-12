;;; lsp.el — 补全 (Company)  -*- lexical-binding: t; -*-

;; ============================================================
;; 补全 (Company)
;; ============================================================
; (use-package company
;   :ensure t
;   :config
;   (global-company-mode)
;   (setq company-idle-delay 0.1
;         company-minimum-prefix-length 2
;         company-backends '(company-files))
;   ;; TAB 确认选中项
;   (define-key company-active-map (kbd "TAB") 'company-complete-selection)
;   (define-key company-active-map (kbd "<tab>") 'company-complete-selection))


(use-package corfu
  :ensure t
  :init
  (progn
    (setq corfu-auto t)
    (setq corfu-cycle t)
    (setq corfu-quit-at-boundary t)
    (setq corfu-quit-no-match t)
    (setq corfu-preview-current nil)
    (setq corfu-min-width 80)
    (setq corfu-max-width 100)
    (setq corfu-auto-delay 0.2)
    (setq corfu-auto-prefix 1)
    (setq corfu-on-exact-match nil)
    (global-corfu-mode)
    ))


(provide 'lsp)
