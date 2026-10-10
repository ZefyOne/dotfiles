;;; .config/doom/lisp/term.el -*- lexical-binding: t; -*-


;; ============================================================
;; 终端 (ghostel)
;; ============================================================
;; ghostel 由 libghostty-vt 驱动 —— 从 Ghostty 终端里抽出来的 VT 解析库，
;; 已在系统里（随 Arch 的 ghostty 包一起装，/usr/lib/libghostty-vt.so）。
;;
;; 它的 native module（Zig 写的）首次运行时会弹窗问「下载预编译二进制还是
;; 自己编译」。这里设成 download 直接跳过询问：x86_64-linux 有官方预编译
;; 产物，因此不需要装 Zig 0.15。
;;
;; 想改成自己编译（需要对应版本的 Zig，见 ghostty.org/docs/install/build）
;; 就把 download 换成 compile；设成 nil 则恢复每次询问。
(with-eval-after-load 'ghostel
  (setq ghostel-module-auto-install 'download))
