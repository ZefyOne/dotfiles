;;; 关于eaf的配置

;; ============================================================
;; eaf框架（目录存在才加载，避免新电脑未 clone EAF 时崩溃）
;; ============================================================
(when (file-exists-p "~/.local/share/emacs/site-lisp/emacs-application-framework/")
  (add-to-list 'load-path "~/.local/share/emacs/site-lisp/emacs-application-framework/")
  (setq eaf-python-command (expand-file-name ".python-env/bin/python" user-emacs-directory))

  ;; EAF 数据目录 → ~/.local/share/emacs/eaf/
  (setq eaf-config-location "~/.local/share/emacs/eaf/")

  (require 'eaf)
  (require 'eaf-video-player)
  (require 'eaf-pdf-viewer)
  (require 'eaf-js-video-player)
  (require 'eaf-git)
  (require 'eaf-image-viewer)
  (require 'eaf-browser)
  (require 'eaf-camera)
  (require 'eaf-org-previewer)
  (require 'eaf-file-manager)
  (require 'eaf-rss-reader)
  (require 'eaf-terminal)
  (require 'eaf-music-player)
  (require 'eaf-markdown-previewer)

  ;; 给浏览器插件换搜索引擎
  (setq eaf-browser-default-search-engine "bing"))
; (setenv "QT_MEDIA_BACKEND" "gstreamer")


(provide 'my-eaf)
