;;; vim.el — Vim 模拟

(use-package evil
  :ensure t
  :custom
  (evil-undo-system 'undo-redo)
  :config
  (evil-mode 1))

(provide 'vim)
