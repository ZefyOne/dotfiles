;;; writing.el -*- lexical-binding: t; -*-

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
  "统计 BEG 到 END 之间的非空白字符数。

`how-many' 内部走 re-search-forward，会冲掉匹配数据。本函数被挂在
全局的 before/after-change-functions 上，若不保护，任何依赖匹配数据
跨越 buffer 变更的代码都会读到 nil —— org 的 org--align-node-property
就是这么把属性抽屉写成 \"nil        nil\" 的。"
  (save-match-data
    (- (- end beg) (how-many "[[:space:]]" beg end))))

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


;; writeroom-mode-line 默认 nil 会连 mode line 一起藏掉，
;; 设成 t 才能保住上面那个模式行字数统计，对应f7
;; 对应keymaps.el中的38行内容，f7切换专注模式
(after! writeroom-mode
    (setq writeroom-mode-line t))







;; ============================================================
;; writing配置,rime
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
  ;; 组字期间 rime 会把自己的 keymap 推进 `overriding-terminal-local-map' ——
  ;; Emacs 里优先级最高的那一个，压过 evil 的 insert state，也压过一切 major
  ;; mode。默认表里的 C-n / C-p 会让组字时按这两个键变成翻候选，而不是执行下面
  ;; 绑的 next-line / previous-line；其他 buffer（比如 .el 文件，不在
  ;; +rime/prose-modes 里）rime 不激活，所以一切照旧。
  ;; 这里把它们从表里摘掉，翻候选改交给 <up> / <down>，功能不丢。
  ;; `rime-activate' 只会照这张表增补绑定、从不清旧账，所以重新激活输入法也
  ;; 没用（旧绑定还在），必须重启 Emacs。
  (rime-translate-keybindings
   '("C-f" "C-b" "C-g"
     "<left>" "<right>" "<up>" "<down>" "<prior>" "<next>" "<delete>"))
  :config
  (add-hook 'after-change-major-mode-hook #'+rime/activate-in-prose-buffer))

(use-package! isearch-mb
  :demand t
  :config
  (isearch-mb-mode +1)
  (map! :map isearch-mb-minibuffer-map
        "C-u" (lambda () (interactive) (kill-line 0))
        "C-w" #'backward-kill-word))


