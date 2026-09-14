;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; 在这里放你的个人配置！注意：修改此文件之后不需要运行 'doom sync'。


;; 有些功能会用到这些信息来识别你，比如 GPG 配置、邮件客户端、文件模板和代码片段。
;; 这一项是可选的。
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")


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
;; 全局加载模块
;; ============================================================
(load! "lisp/options.el")       ; 属性
(load! "lisp/theme.el")         ; 主题
(load! "lisp/ui.el")            ; 界面设置
(load! "lisp/my-org.el")        ; org-mode配置
(load! "lisp/writing.el")       ; 写作
(load! "lisp/keymaps.el")       ; 全局快捷键
