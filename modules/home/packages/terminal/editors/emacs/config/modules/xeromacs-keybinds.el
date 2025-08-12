;;; xeromacs-keybinds.el --- Keybinding configuration using General -*- lexical-binding: t; -*-

;; Author: Zach Bedewi
;; Package-Requires: ((emacs "30"))
;; Keywords: maintenance, convenience, keybinding
;; Version: 1.0

;;; Commentary:
;; Configures general and some global keybinds used throughout the
;; configuration

;;; Code:

(use-package general
  :ensure (:wait t)
  :demand t)

(general-create-definer leader
                        :prefix "SPC")

(leader
 :keymaps 'normal
 ":" 'execute-extended-command
 "f f" 'find-file)

(provide 'xeromacs-keybinds)
