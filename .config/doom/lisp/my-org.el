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


;; ----------------------------------------
;; 闪念笔记落点：inbox.org
;; ----------------------------------------
;; 复用 Doom 自己的 "n"（Personal notes）模板，它的形状正好合适：
;;
;;   ("n" "Personal notes" entry
;;    (file+headline +org-capture-notes-file "Inbox")
;;    "* %u %?\n%i\n%a" :prepend t)
;;
;;   %u  时间戳        %?  光标落点
;;   %i  初始内容      %a  注解：自动记下你捕获时所在的位置
;;
;; `%a' 是关键——在卡片里按 SPC n n n，新条目末尾会自动带上指向那张卡的
;; 链接，日后处理闪念时知道它从哪来的。
;;
;; 模板里存的是 `+org-capture-notes-file' 这个**符号**而不是它的值，
;; capture 时才求值，所以在这里改指向就行，不用动模板本身。
(setq +org-capture-notes-file
      (expand-file-name "~/Documents/zettelkasten/inbox.org"))

;; inbox.org 不是 org-roam 节点（没有 :ID:），所以不会出现在 SPC n r f 里，
;; 得单独给它一个入口。SPC n i 正好空着，也在 notes 前缀下。
(defun +org/open-inbox ()
  "打开卡片盒的闪念笔记收件箱。"
  (interactive)
  (find-file +org-capture-notes-file))


;; ----------------------------------------
;; 网状图：org-roam-ui
;; ----------------------------------------
;; 浏览器里的力导向图，观感对标 Obsidian 的 graph view —— 2D 模式画的就是
;; **圆点**，节点大小随链接数变化，标签在缩小时淡出。另有一个 3D 模式。
;;
;; 它和 Emacs 之间是双向的：在这边切卡片，图上跟着高亮居中（`org-roam-ui-follow'）；
;; 在图里点节点，直接在 Emacs 里打开那个文件，而不是在浏览器里预览。
;; 服务默认地址 http://127.0.0.1:35901/ （`org-roam-ui-port'）。
;;
;; 面板里最该动的几项：
;;   Filter → Directory filters —— 黑白名单，可以直接把 literature/ 滤掉，
;;                                 只看永久笔记之间那张网
;;   Filter → Tag colors        —— 按标签给节点上色
;;   Filter → Orphans           —— 孤立节点显隐
;;   Visual → Node degree size multiplier / Label dynamicity —— 调观感
;;
;; 这里**故意不挂 after-init**：起服务 + 查一次数据库会明显拖慢启动，而这个图
;; 不是每天都要看的东西（日常的"网络感"靠反链缓冲区就够）。用 SPC n g 按需起。
(use-package! org-roam-ui
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme t         ; 跟随 Emacs 当前主题
        org-roam-ui-follow t             ; 图跟随当前正在编辑的卡片
        org-roam-ui-update-on-save t     ; 存盘后自动刷新
        org-roam-ui-open-on-start nil))  ; 不要每次启动都弹浏览器

(defun +org/roam-ui ()
  "启动 org-roam-ui 服务，并在浏览器中打开网状图。"
  (interactive)
  (org-roam-ui-mode +1)
  (org-roam-ui-open))


;; 重写 SPC n 整个菜单的提示，英文后面补中文。
;;
;; 关键：这里必须用 `:prefix-map' 而不是 `:prefix'。
;;   :prefix-map  —— 复用/扩展现有的具名前缀（合并）
;;   :prefix      —— 新建一个匿名前缀地图并绑到该键上，会把原有的整个顶掉
;; Doom 自己的规范是顶层用 `:prefix-map'，嵌套才用 `:prefix'。
(map! :leader
      (:prefix-map ("n" . "notes")
       :desc "Org capture 捕获"                          "n" #'org-capture
       :desc "打开 inbox"                                "i" #'+org/open-inbox
       :desc "卡片盒网状图"                              "g" #'+org/roam-ui
       :desc "Org agenda 日程"                           "a" #'org-agenda
       :desc "Todo list 待办列表"                        "t" #'org-todo-list
       :desc "Tags search 按标签搜索"                    "m" #'org-tags-view
       :desc "Search notes 搜索笔记"                     "s" #'+default/org-notes-search
       :desc "Search notes for symbol 搜当前符号"        "*" #'+default/search-notes-for-symbol-at-point
       :desc "Search agenda headlines 搜日程标题"        "S" #'+default/org-notes-headlines
       :desc "View search 视图搜索"                      "v" #'org-search-view
       :desc "Find file in notes 在笔记里找文件"         "f" #'+default/find-in-notes
       :desc "Browse notes 浏览笔记"                     "F" #'+default/browse-notes
       :desc "Store link 存链接"                         "l" #'org-store-link
       :desc "Goto capture 跳到捕获处"                   "N" #'org-capture-goto-target
       :desc "Toggle last clock 切换上次计时"            "c" #'+org/toggle-last-clock
       :desc "Cancel clock 取消当前计时"                 "C" #'org-clock-cancel
       :desc "Active clock 跳到计时处"                   "o" #'org-clock-goto
       :desc "Export to clipboard 导出到剪贴板"          "y" #'+org/export-to-clipboard
       :desc "Export as RTF 导出为 RTF"                  "Y" #'+org/export-to-clipboard-as-rich-text))

;; SPC n n 之后弹出的模板列表，描述来自 `org-capture-templates'。
;; 模板是 (KEY DESC TYPE TARGET ...) 的列表，改描述就是改第 2 项。
(after! org-capture
  (dolist (zh '(("t" . "待办 Personal todo")
                ("n" . "笔记 Personal notes")
                ("j" . "日记 Journal")
                ("p" . "项目模板 Templates for projects")
                ("o" . "集中式项目模板 Centralized project templates")))
    (when-let* ((cell (assoc (car zh) org-capture-templates)))
      (setcar (cdr cell) (cdr zh)))))


;; ----------------------------------------
;; 建卡模板
;; ----------------------------------------
;; 按「笔记类型」分子目录（permanent / literature），不按主题分 —— 主题留给
;; 链接和标签，因为一张卡可以同时属于好几个主题，而文件夹只能放一个。
;;
;; 标签写在 `#+filetags:' 里，且必须在属性抽屉**外面**。org 的标签机制读的是
;; `#+filetags:' 和标题上的 `:tag:'，属性抽屉里的 `:ROAM_TAGS:' 是不生效的。
;;
;; 文件名用 `${slug}'，也就是标题本身。中文标题过一遍 `org-roam-node-slugify'
;; 几乎原样保留（Emacs 的 `[:alnum:]' 把 CJK 也算作字母），所以文件名读起来
;; 就是标题，dired / 文件管理器里一眼可辨。
;;
;; 为什么不用 `${title}' 原样落盘：slugify 会把 `[^[:alnum:]]' 全部替换成 `_'，
;; 这一步顺带保证了文件名合法 —— 标题里出现 `/ : ? * |' 这些字符都不会出事。
;; 直接写 `${title}' 的话，标题里带一个斜杠就会变成路径分隔符。
;; 代价是英文词被转小写、标点变下划线，可接受。
;;
;; 注意：文件名只在建卡那一刻从标题生成。之后改 `#+title:' 不会自动改文件名，
;; 需要手动 M-x rename-visited-file 同步。
;;
;; ${id} 由 org-roam 在填模板前就生成好了，可以直接引用。
;; 目录要先存在，org-capture 不会替你创建父目录。
(after! org-roam
  (setq org-roam-capture-templates
        `(("d" "永久笔记" plain "%?"
           :target (file+head "permanent/${slug}.org"
                              ":PROPERTIES:
:ID: ${id}
:CREATED: %<%Y-%m-%d>
:SOURCE:
:END:
#+title: ${title}
#+filetags:
")
           :unnarrowed t)
          ("l" "文献笔记" plain "%?"
           :target (file+head "literature/${slug}.org"
                              ":PROPERTIES:
:ID: ${id}
:CREATED: %<%Y-%m-%d>
:SOURCE:
:LOC:
:END:
#+title: ${title}
#+filetags:
")
           :unnarrowed t))))


;; 访问卡片时自动打开右侧反链缓冲区。
;; Doom 的默认值是 nil，需要手动开启。
;;
;; 打开后，只要当前 buffer 是卡片盒里的文件，右侧就常驻反链面板；切走或
;; 全部关掉时自动收起。
;;
;; 这是"双链"体感的来源：你只写**单向**链接，反方向由 org-roam 从数据库
;; 里算出来显示在这里。所以不需要、也不应该手写回链。
;;
;; 副作用是窗口布局会随 buffer 切换变动。觉得吵就把下面这行注掉，改用
;; `M-x org-roam-buffer-toggle' 手动开。
;; (setq +org-roam-auto-backlinks-buffer t)


;; 反链侧边栏太宽 —— 覆盖默认宽度。
;;
;; Doom 的 contrib/roam.el 里写死了 `:side right, :width 0.33'，也就是帧宽的
;; 33%，屏幕越宽它越胖。`set-popup-rule!' 是 push 到 `+popup--display-buffer-alist'
;; 队首，而 `display-buffer-alist' 先匹配先赢，所以这里后定义的规则会盖掉模块自带的。
;;
;; 其余参数（`:height :ttl :modeline :quit :slot'）必须原样抄一遍，否则会退回默认值。
;;
;; `:width' 传小数是帧宽比例，传整数则是固定的字符列数。宽屏下固定列数更稳，
;; 比如 `:width 72' 就是恒定 72 列 —— 嫌比例缩放的可以换成整数。
(after! org-roam
  (set-popup-rule! "^\\*org-roam\\*$"
    :side 'right :width 0.22 :height 0.5 :ttl nil :modeline nil :quit nil :slot 1))


;; 从反链面板跳转时，不要另开一个窗格。
;;
;; 症状：在右侧反链里按 RET 打开一张卡片，卡片会在主窗格**下面**多出一个窗格，
;; 而不是像普通切换缓冲区那样直接替换主窗格的内容。
;;
;; 原因是一条三步链条：
;;   1. 反链里的 RET 经 `org-roam-buffer-visit-thing' 派发到 `org-roam-node-visit'
;;      （org-roam-mode.el:167 / :359）
;;   2. `org-roam-node-visit' 固定用 `pop-to-buffer-same-window' 来显示
;;      （org-roam-node.el:489）
;;   3. 但侧边栏是 Doom 的 popup 窗口，`+popup--init' 把它设成了 dedicated
;;      （popup.el:160）；而 `pop-to-buffer-same-window' 拒绝在 dedicated 窗口里
;;      显示，于是失败并回退成「新开一个窗口」。又因为 `+popup--split-window'
;;      只在非 popup 窗口上切分（popup.el:128），新窗口就落在主区域下方。
;;
;; 所以换键位解决不了（`C-u RET' 走 `switch-to-buffer-other-window'，照样切分）。
;; 这里的做法是：只在 popup 里跳转时，先把光标切到主窗口，再让 org-roam 原来那套
;; 逻辑照常跑 —— 此时当前窗口不再是 dedicated，就会正常原地替换。
;;
;; 三个命令都要 advice：反链条目、反链下方的预览块、未链接引用走的是三个不同的
;; 函数（org-roam-mode.el:424 / :608），漏掉的话点预览仍然会多开窗格。
;;
;; `+popup-window-p' 判断保证只在 popup 里生效，普通窗口中的跳转行为完全不变。
(after! org-roam
  (defun +org-roam--main-window ()
    "返回当前 frame 里第一个非 popup 窗口，也就是主窗格。"
    (seq-find (lambda (win) (not (+popup-window-p win)))
              (window-list nil 'no-minibuf)))

  (defun +org-roam--visit-from-popup-a (fn &rest args)
    "从反链侧边栏跳转时，先在主窗口里显示，而不是另开一个窗格。"
    (let ((main (and (+popup-window-p (selected-window))
                     (+org-roam--main-window))))
      (when main (select-window main))
      (apply fn args)))

  ;; `advice-member-p' 判断是为了让 `doom/reload' 反复执行时不会重复叠加 advice。
  (dolist (cmd '(org-roam-node-visit      ; 反链条目
                 org-roam-preview-visit   ; 反链下方的预览块
                 org-roam-grep-visit))    ; 未链接引用 / grep 结果
    (unless (advice-member-p #'+org-roam--visit-from-popup-a cmd)
      (advice-add cmd :around #'+org-roam--visit-from-popup-a))))


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
