;;; keybind.el --- Easy key binding configuration with Evil integration -*- lexical-binding: t; -*-

;; Author: User
;; Version: 1.0.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: convenience, keybindings, evil
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:
;; This module provides a convenient interface for setting up key bindings
;; in Emacs with full Evil mode support, which-key integration, and declarative syntax.

;;; Code:

(require 'cl-lib)

(defgroup keybind nil
  "Easy key binding configuration."
  :group 'convenience
  :prefix "bind-")

(defcustom bind-leader-key "SPC"
  "Default leader key prefix for leader-based bindings."
  :type 'string
  :group 'keybind)

(defcustom bind-local-leader-key "SPC m"
  "Default local leader key prefix for mode-specific leader bindings."
  :type 'string
  :group 'keybind)

(defvar bind--bindings-registry nil
  "Registry of all bindings created with this module.")

(defvar bind--deferred-bindings nil
  "List of bindings to apply when modes are loaded.")

(defvar bind--which-key-prefixes nil
  "List of which-key prefixes to register.")

(defstruct bind-entry
  type         ; :global, :leader, :local-leader, :mode, :evil
  key
  command
  description
  mode         ; for mode-specific bindings
  evil-state   ; for evil bindings
  condition    ; :when condition
  active-p)    ; whether binding is currently active

;;;###autoload
(defmacro bind (&rest args)
  "Main macro for declarative key binding configuration.
Supports :leader, :local-leader, :global, :modes, and :evil sections."
  (declare (indent 0))
  (let ((leader bind-leader-key)
        (local-leader bind-local-leader-key)
        (forms nil))
    
    ;; Parse arguments
    (while args
      (let ((section (pop args))
            (bindings (pop args)))
        
        (cond
         ;; Set leader keys
         ((eq section :leader-key)
          (setq leader bindings))
         
         ((eq section :local-leader-key)
          (setq local-leader bindings))
         
         ;; Global bindings
         ((eq section :global)
          (dolist (binding bindings)
            (push (bind--make-global-form binding) forms)))
         
         ;; Leader bindings
         ((eq section :leader)
          (dolist (binding bindings)
            (push (bind--make-leader-form binding leader) forms)))
         
         ;; Mode-specific bindings
         ((eq section :modes)
          (dolist (mode-config bindings)
            (push (bind--make-mode-forms mode-config local-leader) forms)))
         
         ;; Evil bindings
         ((eq section :evil)
          (dolist (state-config bindings)
            (push (bind--make-evil-forms state-config) forms))))))
    
    `(progn
       ,@(reverse (flatten-list forms))
       (bind--setup-which-key))))

(defun bind--make-global-form (binding)
  "Create form for global binding."
  (let* ((key (car binding))
         (command (cadr binding))
         (description (caddr binding))
         (condition (plist-get (cdddr binding) :when)))
    
    `(bind--register-binding
      :type :global
      :key ,key
      :command ,command
      :description ,description
      :condition ',condition)))

(defun bind--make-leader-form (binding leader)
  "Create form for leader binding."
  (let* ((key (car binding))
         (command (cadr binding))
         (description (caddr binding))
         (condition (plist-get (cdddr binding) :when))
         (full-key (concat leader " " key)))
    
    `(progn
       (bind--register-binding
        :type :leader
        :key ,full-key
        :command ,command
        :description ,description
        :condition ',condition)
       (bind--add-which-key-prefix ,leader ,key ,description))))

(defun bind--make-mode-forms (mode-config local-leader)
  "Create forms for mode-specific bindings."
  (let* ((mode (car mode-config))
         (config (cdr mode-config))
         (bindings (plist-get config :bindings))
         (local-leader-bindings (plist-get config :local-leader))
         (keymap (plist-get config :map))
         (forms nil))
    
    ;; Regular mode bindings
    (when bindings
      (dolist (binding bindings)
        (push (bind--make-mode-binding-form mode binding keymap) forms)))
    
    ;; Local leader bindings
    (when local-leader-bindings
      (dolist (binding local-leader-bindings)
        (let* ((key (car binding))
               (command (cadr binding))
               (description (caddr binding))
               (full-key (concat local-leader " " key)))
          (push (bind--make-mode-binding-form mode 
                                               (list full-key command description)
                                               keymap) forms)
          (push `(bind--add-which-key-prefix ,local-leader ,key ,description) forms))))
    
    forms))

(defun bind--make-mode-binding-form (mode binding keymap)
  "Create form for individual mode binding."
  (let* ((key (car binding))
         (command (cadr binding))
         (description (caddr binding))
         (condition (plist-get (cdddr binding) :when)))
    
    `(bind--register-mode-binding
      :mode ',mode
      :key ,key
      :command ,command
      :description ,description
      :keymap ',keymap
      :condition ',condition)))

(defun bind--make-evil-forms (state-config)
  "Create forms for Evil state bindings."
  (let* ((state (car state-config))
         (bindings (cadr state-config))
         (forms nil))
    
    (dolist (binding bindings)
      (let* ((key (car binding))
             (command (cadr binding))
             (description (caddr binding))
             (condition (plist-get (cdddr binding) :when)))
        
        (push `(bind--register-evil-binding
                :state ',state
                :key ,key
                :command ,command
                :description ,description
                :condition ',condition) forms)))
    
    forms))

(defun bind--register-binding (&rest args)
  "Register a global binding."
  (let* ((type (plist-get args :type))
         (key (plist-get args :key))
         (command (plist-get args :command))
         (description (plist-get args :description))
         (condition (plist-get args :condition))
         (entry (make-bind-entry :type type
                                 :key key
                                 :command command
                                 :description description
                                 :condition condition
                                 :active-p t)))
    
    (push entry bind--bindings-registry)
    
    (when (bind--should-activate-p condition)
      (global-set-key (kbd key) command)
      (when description
        (put command 'bind-description description)))))

(defun bind--register-mode-binding (&rest args)
  "Register a mode-specific binding."
  (let* ((mode (plist-get args :mode))
         (key (plist-get args :key))
         (command (plist-get args :command))
         (description (plist-get args :description))
         (keymap (plist-get args :keymap))
         (condition (plist-get args :condition))
         (entry (make-bind-entry :type :mode
                                 :key key
                                 :command command
                                 :description description
                                 :mode mode
                                 :condition condition
                                 :active-p nil)))
    
    (push entry bind--bindings-registry)
    
    (let ((keymap-name (or keymap (intern (concat (symbol-name mode) "-map")))))
      (if (boundp keymap-name)
          (bind--apply-mode-binding keymap-name key command description condition)
        (eval-after-load mode
          `(bind--apply-mode-binding ',keymap-name ,key ,command ,description ',condition))))))

(defun bind--register-evil-binding (&rest args)
  "Register an Evil state binding."
  (let* ((state (plist-get args :state))
         (key (plist-get args :key))
         (command (plist-get args :command))
         (description (plist-get args :description))
         (condition (plist-get args :condition))
         (entry (make-bind-entry :type :evil
                                 :key key
                                 :command command
                                 :description description
                                 :evil-state state
                                 :condition condition
                                 :active-p nil)))
    
    (push entry bind--bindings-registry)
    
    (if (featurep 'evil)
        (bind--apply-evil-binding state key command description condition)
      (eval-after-load 'evil
        `(bind--apply-evil-binding ',state ,key ,command ,description ',condition)))))

(defun bind--apply-mode-binding (keymap-name key command description condition)
  "Apply a mode binding to keymap."
  (when (and (boundp keymap-name)
             (bind--should-activate-p condition))
    (define-key (symbol-value keymap-name) (kbd key) command)
    (when description
      (put command 'bind-description description))))

(defun bind--apply-evil-binding (state key command description condition)
  "Apply an Evil state binding."
  (when (and (featurep 'evil)
             (bind--should-activate-p condition))
    (evil-define-key* state 'global (kbd key) command)
    (when description
      (put command 'bind-description description))))

(defun bind--should-activate-p (condition)
  "Check if binding should be activated based on condition."
  (if condition
      (condition-case nil
          (eval condition)
        (error nil))
    t))

(defun bind--add-which-key-prefix (prefix key description)
  "Add which-key prefix description."
  (when description
    (push (list prefix key description) bind--which-key-prefixes)))

(defun bind--setup-which-key ()
  "Setup which-key integration."
  (when (featurep 'which-key)
    (dolist (prefix bind--which-key-prefixes)
      (let ((leader (car prefix))
            (key (cadr prefix))
            (desc (caddr prefix)))
        (which-key-add-key-based-replacements
          (concat leader " " key) desc)))))

;;;###autoload
(defun bind-list-bindings ()
  "Show all custom key bindings created with this module."
  (interactive)
  (let ((buffer (get-buffer-create "*Bind Registry*")))
    (with-current-buffer buffer
      (erase-buffer)
      (insert "Custom Key Bindings Registry\n")
      (insert "===============================\n\n")
      
      (dolist (entry (reverse bind--bindings-registry))
        (let* ((type (bind-entry-type entry))
               (key (bind-entry-key entry))
               (command (bind-entry-command entry))
               (description (bind-entry-description entry))
               (mode (bind-entry-mode entry))
               (state (bind-entry-evil-state entry))
               (active (bind-entry-active-p entry)))
          
          (insert (format "[%s] %s%s -> %s"
                         (upcase (symbol-name type))
                         (if state (format "(%s) " state) "")
                         key
                         command))
          
          (when mode
            (insert (format " [%s]" mode)))
          
          (when description
            (insert (format " - %s" description)))
          
          (unless active
            (insert " [INACTIVE]"))
          
          (insert "\n")))
      
      (goto-char (point-min))
      (display-buffer buffer))))

;;;###autoload
(defun bind-unbind (type &rest args)
  "Remove a binding by type and key."
  (interactive)
  (pcase type
    (:global (global-unset-key (kbd (car args))))
    (:leader (global-unset-key (kbd (car args))))
    (:mode (let* ((mode (car args))
                  (key (cadr args))
                  (keymap-name (intern (concat (symbol-name mode) "-map"))))
             (when (boundp keymap-name)
               (define-key (symbol-value keymap-name) (kbd key) nil))))
    (:evil (when (featurep 'evil)
             (let ((state (car args))
                   (key (cadr args)))
               (evil-define-key* state 'global (kbd key) nil))))))

;;;###autoload
(defun bind-reload ()
  "Reload all bindings from registry."
  (interactive)
  (message "Reloading all key bindings...")
  (dolist (entry bind--bindings-registry)
    (let* ((type (bind-entry-type entry))
           (key (bind-entry-key entry))
           (command (bind-entry-command entry))
           (description (bind-entry-description entry))
           (mode (bind-entry-mode entry))
           (state (bind-entry-evil-state entry))
           (condition (bind-entry-condition entry)))
      
      (when (bind--should-activate-p condition)
        (pcase type
          (:global (global-set-key (kbd key) command))
          (:leader (global-set-key (kbd key) command))
          (:mode (let ((keymap-name (intern (concat (symbol-name mode) "-map"))))
                   (when (boundp keymap-name)
                     (define-key (symbol-value keymap-name) (kbd key) command))))
          (:evil (when (featurep 'evil)
                   (evil-define-key* state 'global (kbd key) command)))))))
  
  (bind--setup-which-key)
  (message "Key bindings reloaded"))

;;;###autoload
(defun bind-which-key-setup ()
  "Setup which-key integration manually."
  (interactive)
  (bind--setup-which-key)
  (when (featurep 'which-key)
    (which-key-add-key-based-replacements
      bind-leader-key "Leader"
      bind-local-leader-key "Local Leader"))
  (message "which-key integration setup complete"))

(defun flatten-list (lst)
  "Flatten a nested list."
  (cond
   ((null lst) nil)
   ((atom lst) (list lst))
   (t (append (flatten-list (car lst))
              (flatten-list (cdr lst))))))

(provide 'keybind)

;;; keybind.el ends here