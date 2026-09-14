;;; keymaps.el -*- lexical-binding: t; -*-

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

;; i模式快捷键
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

;; n模式快捷键
(map! :n "<f7>" #'+zen/toggle                   ; f7切换专注模式
      :n "H" #'+tabs:previous-or-goto           ; 上一个标签
      :n "L" #'+tabs:next-or-goto)              ; 下一个标签


;; ============================================================
;; 让 insert 态的 C-n / C-p 只做上下移动
;; ============================================================
;; 上面 :i 块里的 C-n / C-p 光写不生效：Doom 把 `+corfu/dabbrev-or-next' 和
;; `+corfu/dabbrev-or-last' 绑在了 `corfu-mode-map' 的*辅助键位图*上
;; （+evil-bindings.el:194-198，整段包在 (:after corfu (:map corfu-mode-map ...)) 里）。
;; evil 查键时辅助键位图排在状态主键位图 `evil-insert-state-map' 之前
;; （evil-core.el:667-672），所以 Doom 那条永远压过我们的 next-line/previous-line，
;; 跟加载先后无关。
;;
;; 这里用同样的写法把它解绑（general 中定义写 nil 即解绑，general.el:2198），
;; 查找就会继续落到 evil-insert-state-map 上的 next-line / previous-line。
;;
;; 弹窗打开时的翻候选不受影响：corfu 用的是 <remap> <next-line>（corfu.el:236-237），
;; 键最终落成 next-line 就会被自动重映射成 corfu-next。
(map! :after corfu
      :map corfu-mode-map
      :i "C-n" nil
      :i "C-p" nil)


;; ============================================================
;; 让 org 文件里的 C-j / C-k / C-h / C-l 找回自己的绑定
;; ============================================================
;; 又是辅助键位图：org-mode 下 Doom 会开 `evil-org-mode'（modules/lang/org/config.el:981），
;; 它的 `evil-org-mode-map' 同样是 insert state 的辅助键位图，优先级高于
;; `evil-insert-state-map'。Doom 在 config.el:996-1019 把 `evil-org-movement-bindings'
;; 的 up/down/left/right（默认就是 k/j/h/l）加个 C- 前缀绑到 insert 态：
;;
;;   C-k -> org-up-element          C-j -> org-down-element
;;   C-h -> org-beginning-of-line   C-l -> org-end-of-line
;;
;; 所以上面 :i 块里那四个键一进 org buffer 就全被顶掉（in el 文件则正常，
;; 因为那里根本没有 evil-org-mode-map）。处理方式同上：解绑。
;;
;; 注：C-l 解绑后落到 `org-delete-char' 而非 `delete-char' —— 这是 org-mode-map
;; 自带的 `[remap delete-char]'（连同 `[remap delete-backward-char]'），属于
;; major mode 的 remap，优先级更高也解不掉，功能上仍是删一个字符。
(map! :after evil-org
      :map evil-org-mode-map
      :i "C-j" nil
      :i "C-k" nil
      :i "C-h" nil
      :i "C-l" nil)
