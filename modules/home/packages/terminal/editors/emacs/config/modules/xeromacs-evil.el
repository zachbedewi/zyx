;;; xeromacs-evil.el --- Vim Emulation -*- lexical-binding: t; -*-

;; Author: Zach Bedewi
;; Package-Requires: ((emacs "30"))
;; Keywords: maintenance, convenience, keybinding
;; Version: 1.0

;;; Commentary:
;; Configures vim modal editing emulation in Emacs through the evil
;; and evil-collection packages

;;; Code:

(use-package evil
  :ensure t
  :commands (evil-mode evil-define-key)
  :hook (elpaca-after-init . evil-mode)

  :init
  ;; Must be defined before evil
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)

  :custom
  ;; Make :s in visual mode operate only on the actual visual selection
  ;; (character or block), instead of the full lines covered by the selection
  (evil-ex-visual-char-range t)
  ;; Use Vim-style regular expressions in search and substitute commands,
  ;; allowing features like \v (very magic), \zs, and \ze for precise matches
  (evil-ex-search-vim-style-regexp t)
  ;; Enable automatic horizontal split below
  (evil-split-window-below t)
  ;; Enable automatic vertical split to the right
  (evil-vsplit-window-right t)
  ;; Disable echoing Evil state to avoid replacing eldoc
  (evil-echo-state nil)
  ;; Do not move cursor back when exiting insert state
  (evil-move-cursor-back nil)
  ;; Make `v$` exclude the final newline
  (evil-v$-excludes-newline t)
  ;; Allow C-h to delete in insert state
  (evil-want-C-h-delete t)
  ;; Enable C-u to delete back to indentation in insert state
  (evil-want-C-u-delete t)
  ;; Enable fine-grained undo behavior
  (evil-want-fine-undo t)
  ;; Allow moving cursor beyond end-of-line in visual block mode
  (evil-move-beyond-eol t)
  ;; Disable wrapping of search around buffer
  (evil-search-wrap nil)
  ;; Whether Y yanks to the end of the line
  (evil-want-Y-yank-to-eol t))

(use-package evil-collection
  :after evil
  :ensure t
  :init
  ;; Must be defined before evil-collection
  (setq evil-collection-setup-minibuffer t)

  :config
  (evil-collection-init))

(provide 'xeromacs-evil)
