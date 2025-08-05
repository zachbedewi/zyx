;;; post-init.el --- Post init -*- no-byte-compile: t; lexical-binding: t; -*-

;; Author: Zach Bedewi
;; Package-Requires: ((emacs "30"))
;; Keywords: maintenance
;; Version: 1.0

;;; Commentary:
;; This file is loaded after the init.el file from the minimal-emacs.d framework.
;; It is responsible for loading various modules and functionality used
;; in this configuration.

;;; Code:

(add-to-list 'load-path (file-name-as-directory
                         (expand-file-name "modules" minimal-emacs-user-directory)))

(require 'xeromacs-compilation)
