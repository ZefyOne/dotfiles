;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; 在这里放你的个人配置！注意：修改此文件之后不需要运行 'doom sync'。


;; 有些功能会用到这些信息来识别你，比如 GPG 配置、邮件客户端、文件模板和代码片段。
;; 这一项是可选的。
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom 提供五个（可选的）变量来控制字体：
;;
;; - `doom-font' -- 使用的主字体
;; - `doom-variable-pitch-font' -- 非等宽字体（在适用的场景下）
;; - `doom-big-font' -- 供 `doom-big-font-mode' 使用；适合做演示或直播时用
;; - `doom-symbol-font' -- 用于符号
;; - `doom-serif-font' -- 用于 `fixed-pitch-serif' face
;;
;; 用 'C-h v doom-font' 查看文档以及更多可接受取值的示例。例如：
;;
;; (setq doom-font (font-spec :family "Fira Code" :size 21 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; 如果你或 Emacs 找不到字体，可以用 'M-x describe-font' 查一下，
;; 用 `M-x eval-region' 执行 elisp 代码，用 'M-x doom/reload-font' 刷新字体设置。
;; 如果 Emacs 还是找不到字体，那多半是字体没装好。字体问题很少是 Doom 的问题！

;; 加载主题有两种方式，前提都是主题已安装且可用。你可以设置 `doom-theme'，
;; 也可以用 `load-theme' 函数手动加载主题。下面是默认配置：

; (setq doom-theme 'doom-one)
;; (setq doom-theme 'doom-flatwhite)
;; (setq doom-theme 'doom-dracula)
(setq doom-theme 'doom-earl-grey)      ;; 淡白色主题


;; 也可以像下面这样同时指定暗色和亮色主题，Doom 会根据系统的明暗设置
;; 决定加载哪一个：
;;
;;   (setq doom-theme '(doom-one   . doom-one-light))   ; (暗色 . 亮色)
;;
;; 如果你想根据系统明暗模式更主动地切换主题，可以去了解 `auto-dark' 包。

;; 决定行号的显示样式。设为 `nil' 会关闭行号。
;; 想要相对行号，就把它设为 `relative'。
(setq display-line-numbers-type t)

(set-face-attribute 'default nil
                    :family "Noto Sans Mono CJK SC"
                    :height 190
                    :weight 'normal)
;; 如果你使用 `org'，又不想把 org 文件放在下面这个默认位置，
;; 就修改 `org-directory'。它必须在 org 加载之前设置好！
(setq org-directory "~/org/")


;; 每次重新配置某个包时，记得把配置包在 `with-eval-after-load' 块里，
;; 否则 Doom 的默认设置可能会覆盖你的配置。例如：
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; 这条规则的例外情况：
;;
;;   - 设置文件/目录类变量（比如 `org-directory'）
;;   - 设置那些明确要求在其包加载之前设置的变量
;;     （用 'C-h v VARIABLE' 查看它们的说明）。
;;   - 设置 doom 变量（即以 'doom-' 或 '+' 开头的变量）。
;;
;; 下面还有一些函数/宏可以帮助你配置 Doom。
;;
;; - `load!' 用于加载相对于本文件的外部 *.el 文件
;; - `add-load-path!' 用于把目录添加到 `load-path'（相对于本文件）。
;;   当你用 `require' 或 `use-package' 加载包时，Emacs 会搜索 `load-path'。
;; - `map!' 用于绑定新的按键
;;
;; 想了解这些函数/宏的信息，把光标移到高亮的符号上按 'K'
;; （非 evil 用户按 'C-c c k'）。这会打开它的文档，其中包含用法示例。
;; 或者用 `C-h o' 查询某个符号（函数、变量、face 等）。
;;
;; 你也可以试试 'gd'（或 'C-c c d'）跳到它们的定义处，看看具体是怎么实现的。


;; ============================================================
;; writing配置
;; ============================================================
(defvar +rime/prose-modes '(text-mode org-mode markdown-mode)
  "在这些 major mode 下自动激活 rime。")

(defun +rime/activate-in-prose-buffer ()
  "在散文类 buffer 中激活 rime。"
  (when (apply #'derived-mode-p +rime/prose-modes)
    (activate-input-method "rime")))

(use-package! rime
  :demand t                  ; 关键:确保 rime 加载并注册输入法
  :custom
  (rime-user-data-dir (doom-user-dir "rime/"))
  (rime-show-candidate 'minibuffer)
  (default-input-method "rime")
  (rime-disable-predicates '(evil-normal-state-p))
  :config
  (add-hook 'after-change-major-mode-hook #'+rime/activate-in-prose-buffer))

(use-package! isearch-mb
  :demand t
  :config
  (isearch-mb-mode +1)
  (map! :map isearch-mb-minibuffer-map
        "C-u" (lambda () (interactive) (kill-line 0))
        "C-w" #'backward-kill-word))


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


;; ============================================================
;; 全局快捷键
;; ============================================================
;; 用spc e来切换树状目录
(map! :leader
      :desc "Project sidebar" "e" #'+treemacs/toggle)

(defun +insert-kill-to-line-start ()
  "删除光标到逻辑行首。"
  (interactive)
  (kill-line 0))

(defun +insert-kill-to-line-end ()
  "删除光标到逻辑行尾，无视 visual-line-mode 软换行。"
  (interactive)
  (let ((end (save-excursion (end-of-line) (point))))
    (when (> end (point))
      (kill-region (point) end))))

(map! :i "C-e"   #'end-of-line
      :i "C-l"   #'delete-char
      :i "C-a"   #'beginning-of-line
      :i "C-p"   #'previous-line
      :i "C-n"   #'next-line
      :i "C-u"   #'+insert-kill-to-line-start
      :i "C-k"   #'+insert-kill-to-line-end
      :i "C-j"   #'newline
      :i "C-h"   #'delete-backward-char
      :i "C-y"   #'yank
      :i "C-M-n" #'centaur-tabs-forward
      :i "C-M-p" #'centaur-tabs-backward)



;; ============================================================
;; 模式行常显字数：每个非空白字符算 1
;; 汉字 / 字母 / 标点 / emoji 都算，空格、Tab、换行不计
;; 总数增量维护 —— 更新零延迟，且耗时与文件大小无关
;; 有选区时额外显示选中部分的字数（现算，开销与选区大小成正比）
;; ============================================================

(defun +word-count--enabled-p ()
  "当前 buffer 是否显示字数。不想显示的模式加进这个黑名单。"
  (not (or (minibufferp)
           (derived-mode-p 'dired-mode 'ibuffer-mode 'help-mode
                           'completion-list-mode 'messages-buffer-mode))))

(defvar-local +word-count--value nil
  "当前 buffer 的非空白字符数；nil 表示需要全量重算。")

(defvar-local +word-count--range nil
  "上次统计时的窄化范围：nil 表示未窄化，否则为 (POINT-MIN POINT-MAX)。")

(defvar-local +word-count--pending nil
  "变更前记录的 (BEG END COUNT)，供增量计算用。")

(defun +word-count--count (beg end)
  "统计 BEG 到 END 之间的非空白字符数。"
  (- (- end beg) (how-many "[[:space:]]" beg end)))

(defun +word-count--region ()
  "选中区域的非空白字符数；没有选区时返回 nil。

总数走增量缓存，选区只能现算：拖动或 S-<方向键> 改变选区时并不修改
buffer，change 钩子一次都不会触发，缓存无从更新。"
  (when (use-region-p)
    (+word-count--count (region-beginning) (region-end))))

(defun +word-count--recount ()
  "按当前窄化范围全量重算，并记下该范围。"
  (setq +word-count--range (and (buffer-narrowed-p) (list (point-min) (point-max)))
        +word-count--value (+word-count--count (point-min) (point-max))))

(defun +word-count--ensure ()
  "确保缓存与当前 buffer 状态一致；范围变了或还没算过就重算。"
  (when (or (null +word-count--value)
            (not (equal (and (buffer-narrowed-p) (list (point-min) (point-max)))
                        +word-count--range)))
    (+word-count--recount)))

(defun +word-count--before-change (beg end)
  (when (+word-count--enabled-p)
    (setq +word-count--pending (list beg end (+word-count--count beg end)))))

(defun +word-count--after-change (beg end old-len)
  (when (+word-count--enabled-p)
    (let ((b +word-count--pending))
      (setq +word-count--pending nil)
      (if (and +word-count--value
               b
               (= (nth 0 b) beg)
               (= (- (nth 1 b) (nth 0 b)) old-len))
          ;; 正常情况：只算改动的一小段，做差
          (setq +word-count--value
                (+ +word-count--value
                   (- (+word-count--count beg end) (nth 2 b))))
        ;; 兜底：状态对不上就全量重算，慢一次但不会算错
        (+word-count--recount)))))

(add-hook 'before-change-functions #'+word-count--before-change)
(add-hook 'after-change-functions #'+word-count--after-change)

;; C-SPC 只激活 mark，既不移动 point 也不改 buffer，模式行不保证重绘；
;; 取消选区同理，不加这个「选中:N」会赖着不走。
(add-hook 'activate-mark-hook #'force-mode-line-update)
(add-hook 'deactivate-mark-hook #'force-mode-line-update)


(with-eval-after-load 'doom-modeline
  (doom-modeline-def-segment +word-count
    "字数：非空白字符数，有选区时附带显示选中部分的字数。"
    (when (+word-count--enabled-p)
      (+word-count--ensure)
      (let ((sel (+word-count--region)))
        (propertize (if sel
                        (format " %d字 选中:%d" +word-count--value sel)
                      (format " %d字" +word-count--value))
                    'face (doom-modeline-face)
                    'help-echo "字数：汉字/字母/标点各算一个，空格与换行不计"))))

  ;; 把 +word-count 追加到左侧组末尾 —— 即「左侧内容的最右边」
  (doom-modeline-def-modeline 'main
    '(eldoc bar window-state workspace-name window-number modals matches follow
      buffer-info remote-host buffer-position parrot selection-info +word-count)
    '(compilation objed-state misc-info project-name persp-name battery grip irc
      mu4e gnus github debug repl lsp spell minor-modes input-method
      indent-info buffer-encoding major-mode process vcs check time)))



;; ============================================================
;; 写作模式：F7 进出（= writeroom-mode）
;; ============================================================
(map! :n "<f7>" #'+zen/toggle)

;; writeroom-mode-line 默认 nil 会连 mode line 一起藏掉，
;; 设成 t 才能保住上面那个模式行字数统计
(after! writeroom-mode
    (setq writeroom-mode-line t))



;; ============================================================
;; 补全列表的当前行高亮（M-x、SPC 系列命令、C-s 搜索等）
;; ============================================================
;; doom-themes 把 vertico-current 的背景统一设成 region 色，而 earl-grey
;; 的 region 是 eg-berry1 (#F4EAEE)，底色 eg-bg 是 #FCFBF9 —— 只差 3% 亮度，
;; 当前行看着跟没选中一样。这里覆盖成对比明确的颜色。
;; 想更明显：#CDCBC7 (eg-grey3)；想更淡：#ECEBE8 (eg-grey1)
(custom-set-faces!
  '(vertico-current :background "#DDDBD8" :extend t))
