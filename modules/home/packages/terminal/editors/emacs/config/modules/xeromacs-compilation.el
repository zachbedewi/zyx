;;; xeromacs-compilation.el --- Native Compilation Utilities -*- lexical-binding: t; -*-

;; Author: Zach Bedewi
;; Package-Requires: ((emacs "30"))
;; Keywords: maintenance, native-compilation
;; Version: 1.0

;;; Commentary:
;; Native compilation enhances Emacs performance by converting Elisp code into
;; native machine code, resulting in faster execution and improved
;; responsiveness. This module must be loaded at the very beginning of
;; post-initl.el file before all other packages.

;;; Code:
(use-package compile-angel
  :ensure t
  :demand t
  :custom
  (compile-angel-verbose t)

  :config
  ;; The following directive prevents compile-angel from compiling your init
  ;; files. If you choose to remove this push to `compile-angel-excluded-files'
  ;; and compile your pre/post-init files, ensure you understand the
  ;; implications and thoroughly test your code. For example, if you're using
  ;; `use-package', you'll need to explicitly add `(require 'use-package)` at
  ;; the top of your init file.
  (push "/init.el" compile-angel-excluded-files)
  (push "/early-init.el" compile-angel-excluded-files)
  (push "/pre-init.el" compile-angel-excluded-files)
  (push "/post-init.el" compile-angel-excluded-files)
  (push "/pre-early-init.el" compile-angel-excluded-files)
  (push "/post-early-init.el" compile-angel-excluded-files)

  ;; A global mode that compiles .el files before they are loaded.
  (compile-angel-on-load-mode))

(provide 'xeromacs-compilation)
