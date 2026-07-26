;;; lsp.el — 补全 (Company)

;; ============================================================
;; 补全 (Company)
;; ============================================================
(use-package company
  :ensure t
  :config
  (global-company-mode)
  (setq company-idle-delay 0.1
        company-minimum-prefix-length 2
        company-backends '(company-files))
  ;; TAB 确认选中项
  (define-key company-active-map (kbd "TAB") 'company-complete-selection)
  (define-key company-active-map (kbd "<tab>") 'company-complete-selection))

(provide 'lsp)
