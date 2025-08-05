;;; xeromacs-treesitter.el --- Treesitter support -*- lexical-binding: t; -*-

;; Author: Zach Bedewi
;; Package-Requires: ((emacs "30"))
;; Keywords: maintenance, convenience, programming, syntax
;; Version: 1.0

;;; Commentary:
;; Configures treesitter grammars using the treesit-auto package.

;;; Code:

(use-package treesit-auto
  :ensure t
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

(provide 'xeromacs-treesitter)
