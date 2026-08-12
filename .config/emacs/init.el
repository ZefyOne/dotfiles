;;; init.el — 入口文件

;; ============================================================
;; 自定义设置（Customize UI 存到这里）
;; ============================================================
(setq custom-file "~/.local/share/emacs/custom.el")
(load custom-file t)

;; ============================================================
;; 个人lisp代码，都放在.emacs.d/lisp/。配置都在modules
;; ============================================================
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(add-to-list 'load-path "~/.dotfiles/.config/emacs/modules")



;; ============================================================
;; 加载模块（keymaps 最后加载，以便引用各模块中的函数）
;; ============================================================
(require 'archives)      ;; 包管理：ELPA 镜像源（清华/中科大/官方）与优先级、package 初始化
(require 'path)          ;; 存储路径：备份、自动保存、会话恢复及数据文件路径统一管理
(require 'options)       ;; 基础设置：UTF-8 编码等编辑器行为
(require 'ui)            ;; 界面外观：字体、窗口、主题外观
(require 'vim)           ;; Vim 模拟：evil + evil-surround
(require 'writing)       ;; 写作增强：中文引号配对、字数统计、专注模式、rime 中文输入
(require 'filetree)      ;; 文件树：which-key 按键提示、projectile 项目管理、treemacs 侧边栏
(require 'my-org)        ;; Org-mode：任务管理、笔记、日程
(require 'lsp)           ;; 补全：company 自动补全
(require 'file-search)   ;; 文件搜索：vertico 补全菜单、fd 文件搜索、recentf 最近文件、文件操作
(require 'my-eaf)        ;; EAF 外部应用：浏览器、PDF 阅读器等
(require 'keymaps)       ;; 快捷键：所有按键绑定（最后加载，引用各模块函数）



;; 主题加载
; (load-theme 'doom-dracula t)
(load-theme 'doom-earl-grey t)
