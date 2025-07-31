;;; post-init.el --- User configuration -*- lexical-binding: t; -*-

;;; Commentary:
;; User configuration loaded after init.el

;;; Code:

;; Load the key binding module
;; 
;; Elpaca async loading alternatives:
;; Option 1: :wait t - blocks until package is loaded (current approach)
;; Option 2: :after - ensures one package loads after another without blocking
;; Option 3: elpaca declaration body - evaluated synchronously in order
;; Option 4: elpaca-after-init-hook - runs after all packages are activated
;; Option 5: featurep check - conditional loading based on package availability
;; Option 6: with-eval-after-load - runs code after specific feature is loaded

(use-package general
  :ensure (:wait t)
  :demand t)

(load-file "~/.emacs.d/keybind-general.el")
(require 'keybind-general)

(bind
  :leader
  (":" #'execute-extended-command "M-x")
  ("f f" #'find-file "Find file"))

;; Set up which-key prefix for file commands
(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "SPC f" "Files"))
;;; post-init.el ends here
