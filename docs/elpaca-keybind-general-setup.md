# Elpaca, Keybind-General, and Completion Setup Guide

## Overview

This document covers the setup and configuration of:
- Custom keybind-general library for Emacs key bindings
- Elpaca package manager integration with use-package
- Vertico + Orderless completion framework

## Key Issues and Solutions

### 1. Loading General Package with Elpaca

**Problem**: When loading `keybind-general.el` that requires the `general` package, we encountered "Cannot open load file" errors because `general` wasn't loaded synchronously.

**Solutions explored**:

```elisp
;; Elpaca async loading alternatives:
;; Option 1: :wait t - blocks until package is loaded (current approach)
;; Option 2: :after - ensures one package loads after another without blocking
;; Option 3: elpaca declaration body - evaluated synchronously in order
;; Option 4: elpaca-after-init-hook - runs after all packages are activated
;; Option 5: featurep check - conditional loading based on package availability
;; Option 6: with-eval-after-load - runs code after specific feature is loaded
```

**Final working solution**:
```elisp
(use-package general
  :ensure (:wait t)
  :demand t)

(load-file "~/.emacs.d/keybind-general.el")
(require 'keybind-general)
```

### 2. Making Macros Available Outside use-package

**Problem**: The `bind` macro from keybind-general wasn't available outside the `use-package` declaration.

**Solution**: Use `:wait t` to ensure synchronous loading, allowing macros to be available immediately after the declaration.

### 3. Alternative Loading Approaches

#### Option 2: Using `:after` (failed)
```elisp
(use-package keybind-general
  :ensure nil  ; Don't try to install local package
  :after general
  :config
  (load-file "~/.emacs.d/keybind-general.el")
  (require 'keybind-general))
```
**Issue**: Never loaded because no actual package existed.

#### Option 6: Using `with-eval-after-load` (worked)
```elisp
(use-package general :ensure t)

(with-eval-after-load 'general
  (load-file "~/.emacs.d/keybind-general.el")
  (require 'keybind-general)
  
  (bind
    :leader
    (":" #'execute-extended-command "M-x")))
```

## Keybind-General Usage Examples

### Basic Leader Key Binding
```elisp
(bind
  :leader
  (":" #'execute-extended-command "M-x")
  ("f f" #'find-file "Find file"))
```

### Which-Key Integration
```elisp
;; Set up which-key prefix for file commands
(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "SPC f" "Files"))
```

## Completion Framework Configuration

### Vertico + Orderless Setup
Located in `modules/zach-completion.el`:

```elisp
(use-package vertico
  :ensure t
  :config
  (vertico-mode))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :ensure t
  :commands (marginalia-mode marginalia-cycle)
  :hook (elpaca-after-init . marginalia-mode))
```

### Why Partial-Completion for Files?

**Common pattern**: Use `orderless` for commands/variables/buffers, but `partial-completion` for files because:

1. **Performance**: `orderless` can be slow on large directory trees
2. **Precision**: File paths benefit from left-to-right matching
3. **Predictability**: Better for path navigation (`/u/l/b` → `/usr/local/bin`)

### File Finding Limitations

**Issue**: Standard `find-file` with vertico + orderless doesn't provide recursive file search. Typing "post-init" won't find `.emacs.d/post-init.el` from a different directory.

**Solutions**:
1. Use `**/post-init` wildcard pattern in `find-file`
2. Install packages like `consult`, `helm`, or `ivy` for recursive file finding
3. Navigate to the correct directory first

## Final Configuration

### post-init.el
```elisp
;; Load the key binding module
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
```

### Key Lessons

1. **Elpaca async loading**: Use `:wait t` when you need immediate access to package features
2. **Local file loading**: `load-file` + `require` works well for custom elisp files
3. **Macro availability**: Ensure packages are loaded before using their macros
4. **Completion styles**: Hybrid approach (orderless + partial-completion) balances performance and functionality
5. **Which-key integration**: Set up prefix descriptions separately for better UX

## Commands Reference

- `recentf-open-files` - Open recently opened files
- `recentf-open-most-recent-file` - Open most recent file directly
- `find-file` with `**/pattern` - Recursive file search using wildcards