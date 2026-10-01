;;; novel.el -*- lexical-binding: t; -*-

;; ============================================================
;; 小说模式（.nov）
;; ============================================================
;; 一个文件 = 一章正文，里面只有纯文字，没有任何标记语法。
;;
;; 为什么不用现成的格式：
;;   org      Doom 的 org-startup-indented 会开 org-indent-mode，它占着
;;            line-prefix / wrap-prefix（org-indent.el:311-312），和下面的
;;            首行缩进正面冲突；而且 org 级配置会连带影响笔记。
;;   markdown 正文里一个标记字符都没有，解析器只会误读（行首 4 空格
;;            = 代码块，行首 - 或 1. = 列表）。
;;   txt      系统里有 65+ 个机器生成的 .txt（requirements.txt、输入法
;;            词库、.claude/paste-cache），会一起中招。
;;
;; 为什么叫 novel-mode 而不是 nov-mode：nov.el（NonGNU ELPA 上的 EPUB
;; 阅读器）的主模式就叫 nov-mode，nov-mode-map / nov-mode-hook 全都会撞。
;; 对一个既写小说又读小说的人来说这几乎必然会踩到 —— 两个 define-derived-mode
;; 定义同名函数，后加载的赢，auto-mode-alist 里的 .nov 就会被交给 EPUB 解析器。
;;
;; 继承 text-mode 而不是从 nil 起手：text-mode 的父模式本来就是 nil，
;; 函数体只有 5 行、keymap 是空的，没有包袱可甩；而白拿的几样都用得上 ——
;; text-conversion-style（中文输入法支持）、text-mode-syntax-table 里那几条
;; CJK 设置（全角冒号算 word-constituent）、段落按空行界定。

(define-derived-mode novel-mode text-mode "Novel"
  "小说模式。纯正文，每段一行，段间空行分隔，无任何标记语法。")

(add-to-list 'auto-mode-alist '("\\.nov\\'" . novel-mode))


;; ============================================================
;; 首行缩进两格
;; ============================================================
;; line-prefix 只加在「非续行」上（手册 (elisp) Special Properties），
;; 折行后的续行不受影响 —— 正好是中文小说的首行缩进。wrap-prefix 必须
;; 留 nil：一旦设了它，每一条折行都会跟着悬挂缩进，首行缩进就没了。
;;
;; 用 buffer-local 变量而不是 text property：手册说 property 必须铺满
;; 「第一个字到最后一个字」整个区域才可靠，变量没这个限制；而且
;; text-mode / markdown-mode 里这两个属性一次都没出现，不会打架。
;;
;; 用 make-string 而不是直接写字符串字面量：全角空格在编辑器里看不见，
;; 写成那样没法确认到底是几个，也容易被后来的编辑误删。
;;
;; 值必须是两个 U+3000，不能用 (space :width 2) —— 后者的「1」是
;; 帧默认字体的字符宽（这里是 Fira Code 的 15px），两个拉丁字符宽是 30px，
;; 而中文说的「两格」是两个字宽共 50px。实测 (string-pixel-width "中")
;; = 25px，novel-indent 整个 = 50px。
(defvar novel-indent (make-string 2 #x3000)
  "小说每段首行的显示缩进前缀。默认两个全角空格（U+3000）。")

;; 下面这个是**全局**设置，不是 buffer-local —— 放在这里只是因为它的起因是
;; 上面那个 U+3000。
;;
;; 起因：Emacs 会把「长得像空格的非 ASCII 字符」用 nobreak-space face 显形，
;; 好让你发现它们。U+3000 正是这类字符（Unicode 类别 Zs，和 NBSP 同类），
;; 而且是从 Emacs 28 起才被纳入这个机制的（NEWS.28: "now also affects all
;; non-ASCII space characters"）。doom-earl-grey 给 nobreak-space 配了
;; foreground #477A7B + underline t，后果是缩进那两格的下面被画成一条青色
;; 实线，跟其余部分的灰色虚线接不上。
;;
;; 实测证据：渲染后量像素，x=8..57（正好 50px = novel-indent 宽）是 #477A7B
;; 实线，x=60 往后才是 #9E9A95 的虚线。
;;
;; 手册给的做法就是改这个变量（(emacs) Text Display："To disable this,
;; change the variable nobreak-char-display to nil"），并且没有任何
;; buffer-local 的说法，local-variable-if-set-p 也返回 nil，所以只能全局设。
;;
;; 代价：所有 buffer 里的 NBSP、软连字符等都不再被高亮显形。写中文正文
;; 本来也用不到它们，反倒是粘贴网页文本时那些不请自来的 NBSP 会安静下来。
(setq nobreak-char-display nil)


;; ============================================================
;; 打开 .nov 时的默认显示
;; ============================================================
(add-hook! novel-mode
  (setq-local line-prefix novel-indent)   ; 首行缩进两格
  (ruled-lines-mode +1)                   ; 稿纸线（定义在 ui.el）
  (display-line-numbers-mode -1))         ; 稿纸视图不要行号，见下

;; 软换行不在这里开：Doom 核心给所有 text 派生模式都挂了 visual-line-mode
;; （doom-emacs.el:568-569），novel-mode 继承 text-mode，本来就跑得到。
;;
;; 行号反过来，是继承来了得主动关掉的：Doom 在 doom-emacs.el:774-778 把
;; display-line-numbers-mode 挂到了 text-mode-hook 上，所以 .nov 默认带行号。
;; 顺序上没问题 —— text-mode-hook 属于 delayed-mode-hooks 先跑，我们的 -1 后落实。
;;
;; 行距不在这里设 —— ui.el 的「行间距」一节统一管，列表里有 novel-mode。


;; ============================================================
;; j / k 按视觉行移动
;; ============================================================
;; 开了 visual-line-mode 后 evil 的 j/k 默认仍按逻辑行走，而小说一段
;; 就是一个逻辑行 —— 不处理的话按一下 j 直接跳到下一段。
;;
;; 写法沿用 my-org.el:340-343 对 evil-org 的处理，逐 mode 重映射，
;; 不引入 evil-respect-visual-line-mode 那个全局开关。
(after! evil
  (evil-define-key '(normal motion visual) novel-mode-map
    "j" #'evil-next-visual-line
    "k" #'evil-previous-visual-line))
