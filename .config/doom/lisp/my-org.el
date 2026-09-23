;;; my-org.el -*- lexical-binding: t; -*-



;; ============================================================
;; org 渲染：像 Obsidian 那样
;; ============================================================
;; Doom 的 (org +pretty) 已经替你装好了两个包：
;;   org-appear —— 光标移入时才显示 *粗体*、/斜体/、=代码= 的标记源码
;;   org-modern —— 标题、TODO、:tag:、[ ]、优先级、时间戳的常驻美化
(use-package! org-modern
  :init
  (setq org-modern-star 'replace
        org-modern-replace-stars "◉○◈◇✳"
        org-modern-table nil))



;; 如果你使用 `org'，又不想把 org 文件放在下面这个默认位置，
;; 就修改 `org-directory'。它必须在 org 加载之前设置好！
(setq org-directory "~/org/")


;; ============================================================
;; org-roam —— 卡片盒
;; ============================================================
;; 需要在 init.el 里开 (org +pretty +roam)，否则这段不生效。
;;
;; Doom 的 contrib/roam.el 已经替我们处理了：
;;   - 数据库自动同步（org-roam-db-autosync-mode）、延迟建库
;;   - 反链缓冲区、弹出规则、候选模板
;; 它唯一留给用户的设置就是下面这个目录。
;;
;; 必须在 org-roam 加载之前设好，所以放顶层，不要包进 after!。
;; （config.el 开头那条"目录类变量是例外"说的就是这种情况）
(setq org-roam-directory (expand-file-name "~/Documents/zettelkasten/"))


;; 访问卡片时自动打开右侧反链缓冲区。
;; Doom 的默认值是 nil，需要手动开启。
;; (setq +org-roam-auto-backlinks-buffer t)


;; ============================================================
;; 表格视觉对齐（valign）—— 按需触发，不常驻
;; ============================================================
(map! :map org-mode-map :localleader "b v" #'valign-table)

(setq org-modern-table-horizontal nil)          ; 解决分隔线不对齐的问题



;; ============================================================
;; 中文行内强调：让 *粗体* 不必在两侧加空格
;; ============================================================
(after! org
  (setq org-emphasis-regexp-components
        '("-[:space:]('\"{[:nonascii:]"
          "-[:space:].,:!?;'\")}\\[[:nonascii:]"
          "[:space:]" "." 1))
  (org-set-emph-re 'org-emphasis-regexp-components org-emphasis-regexp-components))

(after! org-element
  (defun +org-element--parse-generic-emphasis (mark type)
    "同 `org-element--parse-generic-emphasis'，但允许非 ASCII 字符作边界。"
    (save-excursion
      (let ((origin (point)))
        (unless (bolp) (forward-char -1))
        (let ((opening-re
               (rx-to-string
                `(seq (or line-start (any space ?- ?\( ?' ?\" ?\{) (not ascii))
                      ,mark
                      (not space)))))
          (when (looking-at-p opening-re)
            (goto-char (1+ origin))
            (let ((closing-re
                   (rx-to-string
                    `(seq
                      (not space)
                      (group ,mark)
                      (or (any space ?- ?. ?, ?\; ?: ?! ?? ?' ?\" ?\) ?\} ?\\ ?\[)
                          (not ascii)
                          line-end)))))
              (when (re-search-forward closing-re nil t)
                (let ((closing (match-end 1)))
                  (goto-char closing)
                  (let* ((post-blank (skip-chars-forward " \t"))
                         (contents-begin (1+ origin))
                         (contents-end (1- closing)))
                    (org-element-create
                     type
                     (append
                      (list :begin origin
                            :end (point)
                            :post-blank post-blank)
                      (if (memq type '(code verbatim))
                          (list :value
                                (org-element-deferred-create
                                 t #'org-element--substring
                                 (- contents-begin origin)
                                 (- contents-end origin)))
                        (list :contents-begin contents-begin
                              :contents-end contents-end)))))))))))))
  (advice-add #'org-element--parse-generic-emphasis
              :override #'+org-element--parse-generic-emphasis))



;; ============================================================
;; 关掉 org 里的 flycheck —— 绿色波浪线的来源
;; ============================================================
(after! flycheck
  (setq flycheck-global-modes '(not org-mode)))



;; ============================================================
;; 恢复 j / k 的视觉行移动
;; ============================================================
(after! evil-org
  (evil-define-key '(normal motion visual) evil-org-mode-map
    "j" #'evil-next-visual-line
    "k" #'evil-previous-visual-line))
