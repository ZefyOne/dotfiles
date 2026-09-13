;;; $DOOMDIR/init.el -*- lexical-binding: t; -*-

;; 这个文件控制启用哪些 Doom 模块，以及它们以什么顺序加载。
;; 修改之后记得运行 'doom sync'！

;; 注意：按 'SPC h d h'（非 vim 用户按 'C-h d h'）可以打开 Doom 的文档。
;;   在那里你能找到 Doom 模块索引的链接，里面列出了我们所有的模块，
;;   以及它们支持哪些 flag。

;; 注意：把光标移到某个模块名（或它的 flag）上按 'K'
;;   （非 vim 用户按 'C-c c k'）即可查看它的文档。对 flag（那些以加号开头的
;;   符号）同样有效。
;;
;;   或者，在模块上按 'gd'（或 'C-c c d'）可以浏览它的目录
;;   （方便直接查看源码）。

(doom! :input
       ;;bidi              ; 帮你把字反着写（从右往左）
       ;;chinese
       ;;japanese
       ;;layout            ; auie,ctsrnm 才是更优秀的主行键位

       :completion
       ;;company           ; 终极代码补全后端
       (corfu +orderless)  ; 用 cap(f)、cape 和一片飞羽来补全！
       ;;helm              ; 为爱与生活而生的*另一个*搜索引擎
       ;;ido               ; 另一个*另一个*搜索引擎……
       ;;ivy               ; 为爱与生活而生的搜索引擎
       vertico           ; 未来的搜索引擎

       :ui
       ;;deft              ; Emacs 版的 notational velocity
       doom              ; 让 DOOM 看起来像 DOOM 的东西
       dashboard         ; Emacs 的漂亮启动画面
       doom-quit         ; 退出 Emacs 时显示 DOOM 风格的追问提示
       ;;(emoji +unicode)  ; 🙂
       hl-todo           ; 高亮 TODO/FIXME/NOTE/DEPRECATED/HACK/REVIEW
       ;;indent-guides     ; 高亮显示缩进列
       ;;ligatures         ; 连字和符号，让你的代码重新变好看
       minimap           ; 在侧边显示代码地图
       modeline          ; 时髦的 Atom 风格 modeline，外加 API
       ;;nav-flash         ; 大幅移动后闪烁一下光标所在行
       ;;neotree           ; 项目侧边栏，类似 vim 的 NERDTree
       ophints           ; 高亮操作所作用的区域
       (popup +defaults)   ; 驯服那些突然出现又不可避免的临时窗口
       ;;smooth-scroll     ; 顺滑到你不敢相信这不是黄油
       tabs              ; Emacs 的标签栏
       treemacs          ; 项目侧边栏，像 neotree 但更酷
       ;;unicode           ; 为各种语言提供扩展 unicode 支持
       (vc-gutter +pretty) ; 在 fringe 中显示 vcs diff
       vi-tilde-fringe   ; 用 fringe 波浪号标记文件末尾之后的行
       window-select     ; 可视化切换窗口
       workspaces        ; 标签页模拟、持久化与独立工作区
       zen               ; 无干扰地编码或写作

       :editor
       (evil +everywhere); 到黑暗面来吧，我们有饼干
       file-templates    ; 空文件自动插入模板
       fold              ; （近乎）通用的代码折叠
       ;;(format +onsave)  ; 自动美化
       ;;god               ; 不用修饰键也能运行 Emacs 命令
       ;;lispy             ; 给 lisp 的 vim，送给不喜欢 vim 的人
       ;;multiple-cursors  ; 同时在多个地方编辑
       ;;objed             ; 给纯良之人的文本对象编辑
       ;;parinfer          ; 把 lisp 变成 python，差不多吧
       ;;rotate-text       ; 在光标处的候选文本之间循环切换
       snippets          ; 我的小精灵。它们替我打字，我就不用自己动手了
       (whitespace +guess +trim)  ; 你空白字符的管家
       ;;word-wrap         ; 带语言感知缩进的软换行

       :emacs
       dired             ; 让 dired 变好看[功能完整]
       electric          ; 更聪明的、基于关键字的 electric-indent
       ;;eww               ; 互联网太糟糕了
       ;;ibuffer           ; 交互式缓冲区管理
       tramp             ; 让你僵硬的手指也能操作远程文件
       undo              ; 持久、更聪明的撤销，专为你的必然失误准备
       vc                ; 版本控制与 Emacs，坐在同一根树枝上

       :term
       ;;eshell            ; 到处都能用的 elisp shell
       ;;shell             ; Emacs 的简单 shell REPL
       ;;term              ; Emacs 的基础终端模拟器
       vterm             ; 几乎是 Emacs 里最好的终端模拟
       ;;ghostel           ; Emacs 里最好的终端模拟

       :checkers
       syntax              ; 你每忘掉一个分号就抽你一下
       ;;(spell +flyspell) ; 你把 misspelling 拼错时抽你一下
       ;;grammar           ; 你每犯一个语法错误就抽你一下

       :tools
       ;;ansible
       ;;biblio            ; 替你写一篇博士论文（需要引用来源）
       ;;collab            ; 和朋友共享缓冲区
       ;;debugger          ; 单步调试代码，帮你制造 bug
       ;;direnv
       ;;docker
       ;;editorconfig      ; 让别人去争论 tab 还是空格
       ;;ein               ; 用 emacs 驯服 Jupyter notebook
       (eval +overlay)     ; 运行代码，运行（还有 repl）
       lookup              ; 浏览你的代码及其文档
       ;;llm               ; 我说你需要朋友，但不是指这种……
       ;;(lsp +eglot)      ; M-x vscode
       magit             ; Emacs 的 git porcelain
       ;;make              ; 从 Emacs 运行 make 任务
       ;;pass              ; 给极客的密码管理器
       ;;pdf               ; pdf 增强
       ;;terraform         ; 基础设施即代码
       ;;tmux              ; 与 tmux 交互的 API
       ;;tree-sitter       ; 语法与解析，坐在树枝上……
       ;;upload            ; 通过 ssh/ftp 把本地项目映射到远程

       :os
       (:if (featurep :system 'macos) macos)  ; 改善与 macOS 的兼容性
       ;;tty               ; 改善终端 Emacs 的体验

       :lang
       ;;ada               ; 我们（盲目地）相信强类型
       ;;(agda +local)     ; 类型的类型的类型的类型……
       ;;beancount         ; 注意 GAAP
       ;;(cc +lsp)         ; C > C++ == 1
       ;;clojure           ; 带 lisp 的 java
       ;;common-lisp       ; 见过一个 lisp，就等于见过所有 lisp
       ;;coq               ; 证明即程序
       ;;crystal           ; c 的速度，ruby 的写法
       ;;csharp            ; unity、.NET 和 mono 的那些破事
       ;;data              ; 配置/数据格式
       ;;(dart +flutter)   ; 画 ui，别的就不多了
       ;;dhall
       ;;elixir            ; 做对了的 erlang
       ;;elm               ; 要来一杯 TEA 吗？
       emacs-lisp        ; 溺死在括号里
       ;;erlang            ; 属于更文明时代的优雅语言
       ;;ess               ; emacs 会说统计
       ;;factor
       ;;faust             ; dsp，但你的灵魂还归你自己
       ;;fortran           ; 在 FORTRAN 中，GOD 是 REAL（除非声明为 INTEGER）
       ;;fsharp            ; ML 代表 Microsoft's Language
       ;;fstar             ; （依赖）类型与（单子）效应，还有 Z3
       ;;gdscript          ; 你一直在等的语言
       ;;(go +lsp)         ; 潮人方言
       ;;(graphql +lsp)    ; 让查询 REST 一下
       ;;(haskell +lsp)    ; 一门比我更懒的语言
       ;;hy                ; scheme 的可读性 + python 的速度
       ;;idris             ; 一门你可以依赖的语言
       ;;json              ; 至少它不是 XML
       ;;janet             ; 有趣的事实：Janet 就是我！
       ;;(java +lsp)       ; 腕管综合征的典型代表
       ;;javascript        ; all(hope(abandon(ye(who(enter(here))))))
       ;;julia             ; 更好、更快的 MATLAB
       ;;kotlin            ; 更好、更时髦的 Java(Script)
       ;;latex             ; 在 Emacs 里写论文从没这么有趣过
       ;;lean              ; 给那些有太多东西要证明的人
       ;;ledger            ; 愿你能做个审计人
       ;;lua               ; 从 1 开始的索引？从 1 开始的索引
       markdown          ; 写给没人看的文档
       ;;nim               ; python + lisp，c 的速度
       ;;nix               ; 我在此宣布 "nix geht mehr!"
       ;;ocaml             ; 一只客观的骆驼
       ;;odin              ; C，去掉了那些会打中自己脚的枪
       (org +pretty)               ; 用纯文本组织你平淡的生活
       ;;php               ; perl 那个不安全的弟弟
       ;;plantuml          ; 把别人搞得更晕的图表
       ;;graphviz          ; 把你自己搞得更晕的图表
       ;;purescript        ; javascript，但是函数式
       ;;python            ; 优美胜于丑陋
       ;;qt                ; 有史以来"最可爱"的 gui 框架
       ;;racket            ; 用来写 DSL 的 DSL
       ;;raku              ; 曾用名 perl6 的那位艺术家
       ;;rest              ; 把 Emacs 当作 REST 客户端
       ;;rst               ; 愿 ReST 安息
       ;;(ruby +rails)     ; 1.step {|i| p "Ruby is #{i.even? ? 'love' : 'life'}"}
       ;;(rust +lsp)       ; Fe2O3.unwrap().unwrap().unwrap().unwrap()
       ;;scad              ; 相信预览，后悔渲染
       ;;scala             ; java，但是好
       ;;(scheme +guile)   ; 一个完全同谋的 lisp 家族
       sh                ; 她在 C 的异或上卖 {ba,z,fi}sh shell
       ;;sml
       ;;solidity          ; 你需要区块链吗？不需要。
       ;;swift             ; 谁要求过 emoji 变量名？
       ;;terra             ; 地球与月亮对齐以换取性能。
       ;;web               ; 那些管子
       ;;yaml              ; JSON，但可读
       ;;zig               ; C，但更简单

       :email
       ;;(mu4e +org +gmail)
       ;;notmuch
       ;;(wanderlust +gmail)

       :app
       ;;calendar
       ;;emms
       ;;everywhere        ; *离开* Emacs！？你开玩笑吧
       ;;irc               ; 胡子宅男们是怎么社交的
       ;;(rss +org)        ; 把 emacs 当作 RSS 阅读器

       :config
       ;;literate
       (default +bindings +smartparens))

;; 如果你是暗色模式用户，每次打开 Emacs 都会被"白屏一闪"折磨，
;; 就取消下面这行的注释（颜色随你喜欢调整）。
;; (add-to-list 'initial-frame-alist '(background-color . "#000000"))

;; 启动时窗口最大化(保留标题栏和窗口装饰)。
;; 想无边框铺满整个屏幕,把值换成 'fullboth。
;; 必须写在 init.el:此文件在 early-init 阶段加载,早于 Emacs 创建首个 frame;
;; 放到 config.el 只会影响之后新开的 frame(C-x 5 2 / emacsclient -c)。
(add-to-list 'initial-frame-alist '(fullscreen . maximized))
(add-to-list 'default-frame-alist '(fullscreen . maximized))
