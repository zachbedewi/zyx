;;; keybind-general.el --- Easy key binding configuration using general.el -*- lexical-binding: t; -*-

;; Author: User
;; Version: 2.0.0
;; Package-Requires: ((emacs "29.1") (general "0.8"))
;; Keywords: convenience, keybindings, evil, general
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; This module provides a convenient interface for setting up key bindings
;; using general.el with Evil mode support, which-key integration, and declarative syntax.
;; Built on top of general.el for maximum compatibility and best practices.

;;; Code:

(require 'general)

(defgroup keybind-general nil
  "Easy key binding configuration using general.el."
  :group 'convenience
  :prefix "bind-")

(defcustom bind-leader-key "SPC"
  "Default leader key prefix for leader-based bindings."
  :type 'string
  :group 'keybind-general)

(defcustom bind-local-leader-key "SPC m"
  "Default local leader key prefix for mode-specific leader bindings."
  :type 'string
  :group 'keybind-general)

(defcustom bind-non-normal-prefix "C-c"
  "Prefix for non-normal state bindings (insert, emacs states)."
  :type 'string
  :group 'keybind-general)

(defvar bind--definers-created nil
  "Track whether custom definers have been created.")

(defvar bind--bindings-registry nil
  "Registry of all bindings created with this module for inspection.")

;;;###autoload
(defun bind-setup-definers ()
  "Setup general.el definers for consistent key binding patterns.
Creates leader, local-leader, and global definers."
  (interactive)
  (unless bind--definers-created
    
    ;; Global leader definer (SPC in normal/visual, C-c in insert/emacs)
    (general-create-definer bind-leader
      :states '(normal visual)
      :prefix bind-leader-key
      :non-normal-prefix bind-non-normal-prefix
      :keymaps 'override)
    
    ;; Local leader definer for mode-specific bindings
    (general-create-definer bind-local-leader
      :states '(normal visual)
      :prefix bind-local-leader-key
      :non-normal-prefix (concat bind-non-normal-prefix " m")
      :keymaps 'override)
    
    ;; Global definer for non-prefixed bindings
    (general-create-definer bind-global
      :keymaps 'override)
    
    ;; Mode-specific definer
    (general-create-definer bind-mode
      :states '(normal visual insert emacs))
    
    ;; Evil state-specific definer
    (general-create-definer bind-evil
      :keymaps 'override)
    
    (setq bind--definers-created t)
    (message "Key binding definers created successfully")))

;;;###autoload
(defmacro bind (&rest config)
  "Main macro for declarative key binding configuration using general.el.
Supports :leader, :local-leader, :global, :modes, and :evil sections.

Example usage:
\(bind
  :leader
  \(\"f f\" #'find-file \"Find file\"
   \"b b\" #'switch-to-buffer \"Switch buffer\")
  
  :modes
  \(python-mode
    :local-leader
    \(\"r\" #'python-shell-send-region \"Send region\")
    :bindings
    \(\"C-c C-c\" #'python-shell-send-buffer \"Send buffer\"))
  
  :evil
  \(:normal
   \(\"g r\" #'xref-find-references \"Find references\")
   :visual
   \(\"g c\" #'comment-or-uncomment-region \"Comment region\")))"
  (declare (indent 0))
  
  ;; Ensure definers are created
  (unless bind--definers-created
    (bind-setup-definers))
  
  (let ((forms '((bind-setup-definers)))
        (current-section nil)
        (current-data nil))
    
    ;; Parse the configuration
    (while config
      (let ((item (pop config)))
        (cond
         ;; Section markers
         ((keywordp item)
          ;; Process previous section if exists
          (when current-section
            (push (bind--process-section current-section current-data) forms))
          ;; Start new section
          (setq current-section item
                current-data nil))
         
         ;; Data for current section
         (t
          (push item current-data)))))
    
    ;; Process final section
    (when current-section
      (push (bind--process-section current-section (reverse current-data)) forms))
    
    ;; Setup which-key integration
    (push '(bind--setup-which-key) forms)
    
    `(progn ,@(reverse forms))))

(defun bind--process-section (section data)
  "Process a configuration section and return appropriate forms."
  (pcase section
    (:leader (bind--process-leader-bindings data))
    (:local-leader (bind--process-local-leader-bindings data))
    (:global (bind--process-global-bindings data))
    (:modes (bind--process-mode-bindings data))
    (:evil (bind--process-evil-bindings data))
    (_ (error "Unknown section: %s" section))))

(defun bind--process-leader-bindings (bindings)
  "Process leader key bindings."
  (let ((processed-bindings (bind--process-binding-list bindings)))
    `(progn
       (bind-leader
        ,@processed-bindings)
       (bind--register-bindings :leader ',processed-bindings))))

(defun bind--process-local-leader-bindings (bindings)
  "Process local leader key bindings."
  (let ((processed-bindings (bind--process-binding-list bindings)))
    `(progn
       (bind-local-leader
        ,@processed-bindings)
       (bind--register-bindings :local-leader ',processed-bindings))))

(defun bind--process-global-bindings (bindings)
  "Process global key bindings."
  (let ((processed-bindings (bind--process-binding-list bindings)))
    `(progn
       (bind-global
        ,@processed-bindings)
       (bind--register-bindings :global ',processed-bindings))))

(defun bind--process-mode-bindings (modes-config)
  "Process mode-specific bindings."
  (let ((forms nil))
    (dolist (mode-config modes-config)
      (let* ((mode (car mode-config))
             (config (cdr mode-config))
             (mode-forms (bind--process-single-mode mode config)))
        (setq forms (append forms mode-forms))))
    `(progn ,@forms)))

(defun bind--process-single-mode (mode config)
  "Process bindings for a single mode."
  (let ((forms nil)
        (current-section nil)
        (current-bindings nil))
    
    ;; Parse mode configuration
    (while config
      (let ((item (pop config)))
        (cond
         ((keywordp item)
          ;; Process previous section
          (when current-section
            (push (bind--make-mode-binding-form mode current-section current-bindings) forms))
          ;; Start new section
          (setq current-section item
                current-bindings nil))
         (t
          (push item current-bindings)))))
    
    ;; Process final section
    (when current-section
      (push (bind--make-mode-binding-form mode current-section (reverse current-bindings)) forms))
    
    (reverse forms)))

(defun bind--make-mode-binding-form (mode section bindings)
  "Create binding form for mode-specific bindings."
  (let ((processed-bindings (bind--process-binding-list bindings))
        (keymap (intern (concat (symbol-name mode) "-map"))))
    
    (pcase section
      (:local-leader
       `(progn
          (bind-local-leader
           :keymaps ',keymap
           ,@processed-bindings)
          (bind--register-bindings :mode-local-leader 
                                   (list ',mode ',processed-bindings))))
      
      (:bindings
       `(progn
          (bind-mode
           :keymaps ',keymap
           ,@processed-bindings)
          (bind--register-bindings :mode-bindings
                                   (list ',mode ',processed-bindings))))
      
      (_ (error "Unknown mode section: %s" section)))))

(defun bind--process-evil-bindings (evil-config)
  "Process Evil state-specific bindings."
  (let ((forms nil)
        (current-state nil)
        (current-bindings nil))
    
    ;; Parse evil configuration
    (while evil-config
      (let ((item (pop evil-config)))
        (cond
         ((keywordp item)
          ;; Process previous state
          (when current-state
            (push (bind--make-evil-binding-form current-state current-bindings) forms))
          ;; Start new state
          (setq current-state item
                current-bindings nil))
         (t
          (push item current-bindings)))))
    
    ;; Process final state
    (when current-state
      (push (bind--make-evil-binding-form current-state (reverse current-bindings)) forms))
    
    `(progn ,@(reverse forms))))

(defun bind--make-evil-binding-form (state bindings)
  "Create binding form for Evil state bindings."
  (let ((processed-bindings (bind--process-binding-list bindings))
        (state-name (intern (substring (symbol-name state) 1)))) ; Remove leading :
    
    `(progn
       (bind-evil
        :states ',state-name
        ,@processed-bindings)
       (bind--register-bindings :evil 
                                (list ',state-name ',processed-bindings)))))

(defun bind--process-binding-list (bindings)
  "Process a list of bindings into key-command pairs."
  (let ((result nil))
    (dolist (binding bindings)
      (let ((key (car binding))
            (command (cadr binding))
            (description (caddr binding)))
        ;; Add key-command pair
        (push key result)
        (push command result)
        ;; Store description for which-key
        (when description
          (bind--add-which-key-description key command description))))
    (reverse result)))

(defvar bind--which-key-descriptions nil
  "Storage for which-key descriptions.")

(defun bind--add-which-key-description (key command description)
  "Store which-key description for later setup."
  (push (list key command description) bind--which-key-descriptions))

(defun bind--setup-which-key ()
  "Setup which-key integration for stored descriptions."
  (when (featurep 'which-key)
    ;; Add leader key descriptions
    (which-key-add-key-based-replacements
      bind-leader-key "Leader"
      bind-local-leader-key "Local Leader")
    
    ;; Add individual command descriptions
    (dolist (desc bind--which-key-descriptions)
      (let ((key (car desc))
            (command (cadr desc))
            (description (caddr desc)))
        (when description
          (which-key-add-key-based-replacements key description))))))

(defun bind--register-bindings (type bindings)
  "Register bindings in the registry for inspection."
  (push (list type bindings) bind--bindings-registry))

;;;###autoload
(defun bind-list-bindings ()
  "Show all custom key bindings created with this module."
  (interactive)
  (let ((buffer (get-buffer-create "*Bind Registry*")))
    (with-current-buffer buffer
      (erase-buffer)
      (insert "Key Bindings Registry (general.el)\n")
      (insert "====================================\n\n")
      
      (dolist (entry bind--bindings-registry)
        (let ((type (car entry))
              (bindings (cadr entry)))
          (insert (format "[%s]\n" (upcase (symbol-name type))))
          (when (listp bindings)
            (let ((i 0))
              (while (< i (length bindings))
                (let ((key (nth i bindings))
                      (command (nth (1+ i) bindings)))
                  (when (and key command)
                    (insert (format "  %s -> %s\n" key command)))
                  (setq i (+ i 2))))))
          (insert "\n")))
      
      (goto-char (point-min))
      (display-buffer buffer))))

;;;###autoload
(defun bind-which-key-setup ()
  "Setup which-key integration manually."
  (interactive)
  (bind--setup-which-key)
  (message "which-key integration setup complete"))

;;;###autoload
(defun bind-reload ()
  "Reload general.el configuration."
  (interactive)
  (message "Reloading general.el key bindings...")
  ;; General.el handles reloading automatically when re-evaluating definitions
  (bind--setup-which-key)
  (message "Key bindings reloaded"))

;; Convenience functions for direct use
;;;###autoload
(defun bind-leader-quick (key command &optional description)
  "Quick leader key binding."
  (interactive)
  (unless bind--definers-created (bind-setup-definers))
  (bind-leader key command)
  (when description
    (bind--add-which-key-description (concat bind-leader-key " " key) command description)
    (bind--setup-which-key)))

;;;###autoload
(defun bind-local-leader-quick (mode key command &optional description)
  "Quick local leader key binding for MODE."
  (interactive)
  (unless bind--definers-created (bind-setup-definers))
  (let ((keymap (intern (concat (symbol-name mode) "-map"))))
    (bind-local-leader
     :keymaps keymap
     key command)
    (when description
      (bind--add-which-key-description (concat bind-local-leader-key " " key) command description)
      (bind--setup-which-key))))

;;;###autoload
(defun bind-global-quick (key command &optional description)
  "Quick global key binding."
  (interactive)
  (unless bind--definers-created (bind-setup-definers))
  (bind-global key command)
  (when description
    (bind--add-which-key-description key command description)
    (bind--setup-which-key)))

;; Initialize definers on load
(bind-setup-definers)

(provide 'keybind-general)

;;; keybind-general.el ends here