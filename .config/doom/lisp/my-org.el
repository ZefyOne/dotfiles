;;; my-org.el -*- lexical-binding: t; -*-



;; ============================================================
;; org 渲染：像 Obsidian 那样
;; ============================================================
;; Doom 的 (org +pretty) 已经替你装好了两个包：
;;   org-appear —— 光标移入时才显示 *粗体*、/斜体/、=代码= 的标记源码
;;   org-modern —— 标题、TODO、:tag:、[ ]、优先级、时间戳的常驻美化
;;
;; 这里只调标题符号。org-modern 默认 org-modern-star 为 'fold —— 拿
;; org-modern-fold-stars 里的 ▶▼ 系列当折叠指示器，所以满屏三角。
;; 换成 'replace 后改为按层级给一个固定符号，"◉○◈◇✳" 依次对应 1~5 级标题，
;; 再往深就沿用最后一个。
;;
;; 必须写在 :init 里：org-modern-mode 启用那一刻就把 font-lock 关键字定死了，
;; 写进 after! 或 with-eval-after-load 都来不及。改完 M-x org-mode-restart 生效。
(use-package! org-modern
  :init
  (setq org-modern-star 'replace
        org-modern-replace-stars "◉○◈◇✳"))



;; 如果你使用 `org'，又不想把 org 文件放在下面这个默认位置，
;; 就修改 `org-directory'。它必须在 org 加载之前设置好！
(setq org-directory "~/org/")
