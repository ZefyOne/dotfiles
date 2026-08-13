;;; archives.el — 包管理：镜像源、优先级、初始化
;;; 从 init.el 拆出，package-initialize 须先于各模块的 use-package 执行

(require 'package)

(setq package-user-dir "~/.local/share/emacs/elpa")

;; 镜像源下签名文件可能滞后或密钥未被信任，跳过签名校验
(setq package-check-signature nil)

(setq package-archives
      '(("gnu"            . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
        ("melpa"          . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")
        ("gnu-ustc"       . "https://mirrors.ustc.edu.cn/elpa/gnu/")
        ("melpa-ustc"     . "https://mirrors.ustc.edu.cn/elpa/melpa/")
        ("gnu-official"   . "https://elpa.gnu.org/packages/")
        ("melpa-official" . "https://melpa.org/packages/")))

(setq package-archive-priorities
      '(("gnu"            . 10)
        ("melpa"          . 10)
        ("gnu-ustc"       . 5)
        ("melpa-ustc"     . 5)
        ("gnu-official"   . 1)
        ("melpa-official" . 1)))

(package-initialize)

(provide 'archives)
