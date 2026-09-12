;;; writing.el — 写作功能  -*- lexical-binding: t; -*-

;; ============================================================
;; 中文引号自动配对
;; ============================================================
(setq electric-pair-pairs
      '((?\" . ?\")
        (?「 . ?」)
        (?' . ?')
        (?【 . ?】)
        (?《 . ?》)))

(electric-pair-mode 1)

;; ============================================================
;; 字数统计
;; ============================================================
(defun writing--count-non-space (begin end)
  "计算区域内的非空白字符数（标点也算，空白不算）。"
  (- (- end begin)
     (how-many "[[:space:]]" begin end)))

(let ((enc '(:eval (format " %s"
                           (upcase (symbol-name
                                    (coding-system-base
                                     (or buffer-file-coding-system 'utf-8)))))))
      (wc  '(:eval (if (use-region-p)
                       (format " 字数:%d 选中:%d"
                               (writing--count-non-space (point-min) (point-max))
                               (writing--count-non-space (region-beginning) (region-end)))
                     (format " 字数:%d"
                             (writing--count-non-space (point-min) (point-max)))))))
  (dolist (item (list enc wc))
    (or (memq item mode-line-format)
        (setq-default mode-line-format
                      (append mode-line-format (list item))))))

;; ============================================================
;; 专注模式 (olivetti)
;; ============================================================
(use-package olivetti
  :ensure t
  :config
  (setq olivetti-body-width 80
        olivetti-minimum-body-width 60
        olivetti-recall-visual-line-mode-entry-state t))

;; ============================================================
;; 中文输入 (rime)
;; ============================================================

;; 旁路断言：代码区与字符串走英文，只有注释里放行中文。
;;
;; 判定依据是 syntax-ppss 返回的解析状态，(nth 4) 非 nil 表示光标处于注释中。
;; 它读的是 major mode 的语法表，所以 //、/* */、#、;; 等各种注释风格自动
;; 覆盖，不必逐语言枚举注释符号，也不会被字符串里的 "//" 干扰。
;;
;; 求值时机：断言并非只在激活输入法时算一次——rime-input-method 每次按键
;; 都会调用 rime--should-enable-p（见 rime.el）。所以在代码里敲 // 时，两个
;; 斜杠本身按英文进来，紧随其后的第一个字就是中文；出了 */ 也会自动切回英文，
;; 全程不需要按 C-\。
;;
;; 取舍：此处不判断 (nth 3)（是否在字符串中），即字符串一律走英文。代价是
;; printf("你好") 这类要手动切一次，换来的是 URL、路径、SQL、i18n key 不会
;; 把人踢进中文态。若中文文案更多，把 (not (nth 3 (syntax-ppss))) 加进 and
;; 即可反转这个取舍。
(defun my-rime-disable-in-code-p ()
  "在 prog-mode 的代码区与字符串中禁用 rime，仅在注释里放行中文。"
  (and (derived-mode-p 'prog-mode)
       (not (nth 4 (syntax-ppss)))))

(use-package rime
  :ensure t
  :custom
  (rime-user-data-dir (expand-file-name "rime/" user-emacs-directory))
  (rime-show-candidate 'minibuffer)
  (default-input-method "rime")
  ;; my-rime-disable-in-code-p 必须定义在本形式之前：不是运行时需要，而是
  ;; rime-disable-predicates 的 Customize 类型是 (repeat function)，widget
  ;; 会做 fboundp 检查，未定义时 M-x customize-variable 会显示成无效项。
  (rime-disable-predicates '(evil-normal-state-p
                             my-rime-disable-in-code-p)))

;; isearch 改用 minibuffer 输入：让 rime 在 isearch 里能正常上屏中文
;; 若候选显示与 minibuffer 输入抢显示，需把 rime-show-candidate 改为 'posframe
(use-package isearch-mb
  :ensure t
  :config
  (isearch-mb-mode 1)
  ;; isearch 输入区复用编辑键（与 file-search 的 vertico-map 保持一致）
  (define-key isearch-mb-minibuffer-map (kbd "C-u")
    (lambda () (interactive) (kill-line 0)))
  (define-key isearch-mb-minibuffer-map (kbd "C-w") 'backward-kill-word))

(defvar my-rime-extensions '("md" "txt" "org")
  "文件后缀，打开时自动激活 rime。")

;; 所有 buffer 默认启用 rime
(run-with-idle-timer 1 nil
  (lambda ()
    (require 'rime)
    (dolist (b (buffer-list))
      (with-current-buffer b
        (when (and (buffer-file-name)
                   (member (file-name-extension (buffer-file-name))
                           my-rime-extensions))
          (activate-input-method "rime"))))))

;; 新打开的文件也启用
(add-hook 'find-file-hook
          (lambda ()
            (when (and (buffer-file-name)
                       (member (file-name-extension (buffer-file-name))
                               my-rime-extensions)
                       (not current-input-method))
              (require 'rime)
              (activate-input-method "rime"))))

;; 代码 buffer 同样要激活 rime。
;; 激活才会把 input-method-function 设为 rime-input-method（rime.el 的
;; rime-activate 里做的），不激活的话 my-rime-disable-in-code-p 根本没机会
;; 运行，前面那套断言在代码里等于没装。
;; (not current-input-method) 这个守卫是安全的：current-input-method 是
;; buffer-local，新 buffer 读到 nil，不会因为别的 buffer 激活过就跳过。
(add-hook 'prog-mode-hook
          (lambda ()
            (require 'rime)
            (unless current-input-method
              (activate-input-method "rime"))))

(provide 'writing)
