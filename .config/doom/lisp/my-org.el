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
;;
;; org-modern-table 关掉表格美化，是为了 valign 的分隔线对齐。
;; org-modern 会把表格里每个字符都换成自己的显示宽度：| 和 + 变成 3px 的空格
;; (space :width 3)，- 变成 org-modern--table-sp-width 宽的空格 —— 屏幕上看到的
;; 竖线根本不是 | 这个字符画的，是它贴的色块。
;;
;; 而 valign--align-separator-row 是按「左边那根竖线占一个完整字形宽」去反推
;; 之后每一列的像素坐标的。被压到 3px 之后，推算每列都差一个字符：数据行靠
;; 单元格内容撑开看不出来，分隔线纯靠坐标摆位，就露馅了。实测同一张表
;;
;;   org-modern-table = t    → 分隔线中间竖线偏 14px、右边偏 42px
;;   org-modern-table = nil  → 偏差 0，与数据行完全重合
;;
;; 代价是表格分隔线变回字面上的 |---+---|，org-modern 那种「空白行 + 3px 短横」
;; 的样式没了。标题符号、TODO、标签、复选框、时间戳都不受影响。
;;
;; 注意 org-modern-table-horizontal 管不了这件事 —— 它只决定那条横线画不画得
;; 出来，设成 nil 或数字，上面那组偏差都是 (0 -14 -42)。
(use-package! org-modern
  :init
  (setq org-modern-star 'replace
        org-modern-replace-stars "◉○◈◇✳"
        org-modern-table nil))



;; 如果你使用 `org'，又不想把 org 文件放在下面这个默认位置，
;; 就修改 `org-directory'。它必须在 org 加载之前设置好！
(setq org-directory "~/org/")


;; ============================================================
;; 表格视觉对齐（valign）—— 按需触发，不常驻
;; ============================================================
;; org 的表格对齐有个前提：汉字恰好占两个英文字符宽。它照这个算好空格，
;; 而实测本机字体（Fira Code-25 量出英文 20px，LXGW 文楷汉字 25px）比值
;; 是 1.25 不是 2，于是 Emacs 以为对齐了，屏幕上每多一个汉字就少 5px，
;; 整列歪掉。
;;
;; valign 绕开字符宽度计算，直接按像素量出单元格实际宽度，用显示层属性
;; 把 | 摆正，文件里的文本一个字节都不改 —— 导出、git diff、别人 clone
;; 看到的都是 org 自己算的那份，歪的只有屏幕。
;;
;; 代价：valign-mode 把 `valign-region' 挂进 `jit-lock-functions'，于是
;; *每次 fontify 都要把整个 buffer 里所有表格逐格重新量一遍像素*，而每量
;; 一次都得走显示引擎排版（中文还要过 fontset 回退，实测约 1.5ms/次）。
;; 开销跟表格数量成正比，跟字数基本无关。实测
;; ~/Desktop/Doom-Emacs-增强功能对照.org（73 个表格 / 763 行 / 63k 字符）：
;;
;;   纯 org fontify            0.08 秒
;;   带 valign 全量对齐一遍   12～14 秒（8229 次 window-text-pixel-size）
;;
;; 而且开一个文件远不止跑一遍：Doom 默认 `org-startup-indented' 会开
;; org-indent-mode，valign 又挂在 `org-indent-mode-hook' 和
;; `org-indent-initialize-agent' 上，各自触发一次全量重排；折叠时
;; `org-cycle-hook' 还会 jit-lock-refontify 整个 buffer。叠加起来就是
;; 「打开文件卡十几秒、打字时光标不动」。没有表格的文件完全不受影响
;; （赶海正文 22 万字节只要 0.06 秒），所以这个坑只在表格多的文件里踩。
;;
;; 因此这里不挂 `org-mode-hook'，改成按需：SPC m b v 只对齐光标所在的那
;; 一个表，开销约 0.1 秒，感觉不到。真想整篇对齐就 M-x valign-region。
;; 想恢复常驻的话把 `valign-mode' 加回 org-mode-hook 即可 —— valign-table
;; 和 valign-mode 都自带 autoload，下面直接绑键不用 use-package!。
;;
;; 另外两条只在你重新开启 valign-mode 时才需要留意：
;;   - 默认只处理 4000 字符以内的表格，更长的套 valign-table-fallback
;;     face 而不对齐；阈值用 `valign-max-table-size' 调。
;;   - valign-mode 施加的是全局 advice，光关 mode 撤不掉，得显式
;;     M-x valign-remove-advice。
(map! :map org-mode-map :localleader "b v" #'valign-table)

(setq org-modern-table-horizontal nil)          ; 解决分隔线不对齐的问题
