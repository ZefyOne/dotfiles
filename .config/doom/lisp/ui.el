;;; ui.el -*- lexical-binding: t; -*-

;; ============================================================
;; 补全列表的当前行高亮（M-x、SPC 系列命令、C-s 搜索等）
;; ============================================================
(custom-set-faces!                                                              ; 在M-x中光标行的颜色，淡蓝
  '(vertico-current :background "#ADD8E6" :extend t))


;; ============================================================
;; 字体配置
;; ============================================================
(setq doom-font (font-spec :family "Fira Code" :size 25 :weight 'medium)
      doom-variable-pitch-font (font-spec :family "Noto Sans CJK SC" :size 25)) ; 设置主要字体，英文和符号是fira code，再加一个兜底

(set-fontset-font t 'han (font-spec :family "LXGW WenKai Mono"))                ; 设置中文字体为这个东西，一个比较知名的楷体，这里面不能用size

(set-fontset-font t 'cjk-misc (font-spec :family "LXGW WenKai Mono"))           ; 解决中文标点垂直居中的问题，加上就正常了




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


;; ---------- 字体 ----------
;; 字号 21 = 你原来 set-face-attribute 里 :height 190（也就是 19pt）之上又调大了 2pt，
;; 想回到原来的大小就写 :size 19。
;;
;; 字重用 'medium：系统里没有 Fira Code SemiLight，写 'semi-light 会被 fontconfig
;; 匹配到 Light，字比预想的细一档。


;; Fira Code 不含汉字字形，这里显式指定 han 脚本用哪个字体，否则只能让系统随意兜底。
;; 霞鹜文楷等宽（LXGW WenKai Mono）——楷体骨架，汉字宽度正好等于两个英文字符
;; （fontconfig 里 spacing=dual），所以代码注释里中英混排也能对齐。
;;
;; 别在这加 :size 或 :weight：一旦写死，中文就不再跟随字号变化和粗体渲染，
;; 放大字号时会出现「英文变大、中文纹丝不动」的错位。留空让它自己继承。




;; 全角标点必须单独设一次。
;;
;; Emacs 的 fontset 是按「script」分槽匹配的，而全角标点（、。，！？：；全角空格……
;; 的 script 是 `cjk-misc'，跟汉字的 `han' 不是同一个槽 —— 只设 han 管不到标点，
;; 它们会掉给 fontconfig 兜底。兜底结果依机器而定，这台机器上落到了
;; Noto Serif CJK TC：台湾规范的标点放在字面框正中央（实测在汉字框 37%~68% 处），
;; 于是就成了「逗号句号浮在文字中间」。霞鹜文楷自己的标点在汉字框 1%~23% 处，
;; 也就是底部，所以补上这一行，标点就归位了。

;; ====================================================================
