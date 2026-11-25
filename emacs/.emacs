;;; ...  -*- lexical-binding: t -*-

(setenv "EDITOR" "emacsclient")
(setenv "VISUAL" "emacsclient")

;; Startup and package setup (Emacs 29+).
(setq-default gc-cons-threshold (* 32 1024 1024))
(setq-default gc-cons-percentage 0.5)
(add-hook 'after-init-hook (lambda () (setq gc-cons-threshold 800000) (setq-default gc-cons-percentage 0.1)))


(require 'package)
(setq package-enable-at-startup nil)
(package-initialize)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(require 'use-package)

;; Core editing and display.
(setq inhibit-startup-message t)
(setq ring-bell-function 'ignore)
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(global-hl-line-mode t)
(setq select-enable-clipboard t)
(recentf-mode 1)
(save-place-mode 1)
(global-auto-revert-mode t)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)
(delete-selection-mode 1)
(blink-cursor-mode -1)
(set-frame-font "BerkeleyMono Nerd Font-14" nil t)
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))
(setq default-directory (expand-file-name "~/"))
(setq command-line-default-directory (expand-file-name "~/"))
(add-to-list 'default-frame-alist '(fullscreen . maximized))
(defalias 'yes-or-no-p 'y-or-n-p)
(define-key y-or-n-p-map (kbd "RET") 'act)
(unless (assoc "xterm-ghostty" term-file-aliases)
  (add-to-list 'term-file-aliases '("xterm-ghostty" . "xterm-256color")))
(electric-pair-mode 1)
(setq-default bidi-display-reordering t
              bidi-paragraph-direction 'left-to-right
              bidi-inhibit-bpa t)
(setq fast-but-imprecise-scrolling t
      redisplay-skip-fontification-on-input t
      inhibit-compacting-font-caches t)
(setq read-file-name-completion-ignore-case t)
(setq read-buffer-completion-ignore-case t)
(setq completion-ignore-case  t)
(setq case-fold-search t)

;; Key bindings.
;; Text manipulation.
(global-set-key (kbd "C-c a") 'align)
(global-set-key (kbd "C-,") 'duplicate-line)
(global-set-key (kbd "C-.") 'kill-whole-line)
(global-set-key (kbd "C-c ,") 'copy-from-above-command)
(global-set-key (kbd "C-c t") 'transpose-lines)
(global-set-key (kbd "C-c /") 'comment-or-uncomment-region)
(global-set-key (kbd "C-c e") 'load-file)

;; navigation
(global-set-key (kbd "C-c i") 'imenu)
(global-set-key (kbd "M-g b") 'beginning-of-defun)
(global-set-key (kbd "M-g e") 'end-of-defun)

;; window management
(global-set-key (kbd "M-<left>")  'windmove-left)
(global-set-key (kbd "M-<right>") 'windmove-right)
(global-set-key (kbd "M-<up>")    'windmove-up)
(global-set-key (kbd "M-<down>")  'windmove-down)

;; development
(global-set-key (kbd "C-c c") 'compile)

;; lsp
(global-set-key (kbd "C-c r") 'eglot-rename)
(global-set-key (kbd "C-c h") 'eldoc)
(global-set-key (kbd "C-c d") 'xref-find-definitions)
(global-set-key (kbd "C-c x") 'xref-find-references)

;; Built-in packages.
(use-package tramp
  :custom
  (enable-remote-dir-locals t)
  (remote-file-name-inhibit-locks t))

(use-package tab-bar
  :config
  (tab-bar-mode -1)
  (tab-bar-history-mode 1)
  :custom
  (tab-bar-show nil))

(use-package help
  :ensure nil
  :bind
  (:map help-map
        ("M" . #'man)))

(use-package eldoc
  :custom
  (eldoc-echo-area-use-multiline-p t)
  (eldoc-echo-area-display-truncation-message nil)
  (eldoc-echo-area-prefer-doc-buffer t)
  (eldoc-documentation-strategy #'eldoc-documentation-compose)
  :bind
  (:map help-map
        ("y" . #'eldoc-print-current-symbol-info)))

(use-package shell
  :commands shell
  :config
  (defun m/uniquify-shell-name-advice (&rest r)
    (rename-buffer
     (format "*shell* (%s)"
             (if (project-current)
                 (project-name (project-current))
               (alist-get 'name (tab-bar--current-tab))))
     t))
  (advice-add #'shell :after #'m/uniquify-shell-name-advice)

  ;; Enable compilation results parsing in shell mode
  (add-hook 'shell-mode-hook 'compilation-shell-minor-mode))

;; (when (eq system-type 'darwin)
(when (daemonp)  
  (use-package exec-path-from-shell
    :ensure t)
  (exec-path-from-shell-initialize))

(global-set-key [remap dabbrev-expand] 'hippie-expand)

(with-eval-after-load 'dired
  (require 'dired-x))

(use-package browse-url
  :config
  (add-to-list 'browse-url-handlers '("hyperspec" . eww-browse-url)))

(use-package savehist
  :config
  (savehist-mode 1)
  :custom
  (savehist-additional-variables '(kill-ring
                                   vertico-repeat-history))
  (history-delete-duplicates t)
  (history-length 10000))

(use-package flymake
  :defer t
  :init
  ;; Emacs 30+ refuses to run Flymake backends in files outside `trusted-content'.
  ;; (setq trusted-content :all) ;; to whitelist everything if necessary
  ;; add /nix/store/ if eglot-extend-to-xref breaks 
  (add-to-list 'trusted-content "~/nix/")
  (add-to-list 'trusted-content "~/code/"))
;; Completion and external packages.
(use-package pretty-sha-path
  :ensure t)
(use-package goto-last-change
  :ensure t
  :bind
    (
    ("M-m" . #'goto-last-change)
    ))
(use-package vundo
  :ensure t
  :commands vundo
  :custom
  (vundo-glyph-alist vundo-unicode-symbols))
(use-package marginalia
  :ensure t
  :init
  (marginalia-mode 1)
  :custom
  (marginalia-align 'left)
  (marginalia-field-width 240)
  :bind (:map minibuffer-local-map
              ("M-m" . marginalia-cycle)))
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic partial-completion))
  (completion-category-overrides '((file (styles basic partial-completion))
                                   (eglot (styles orderless flex basic))))
  (orderless-matching-styles '(orderless-literal orderless-regexp)))
(use-package company
  :ensure t
  :hook (prog-mode . company-mode)
  :config
  (setq company-idle-delay 1)
  (setq company-minimum-prefix-length 2))
(use-package which-key
  :ensure t
  :config
  (which-key-mode))
(use-package magit
  :ensure t
  :commands (magit-status magit-dispatch magit-file-dispatch))
(use-package doom-modeline
  :ensure t
  :hook (after-init . doom-modeline-mode))
(use-package helpful
  :ensure t
  :commands (helpful-callable helpful-function helpful-macro helpful-command
             helpful-variable helpful-key helpful-at-point))
(use-package ace-window
  :ensure t
  :bind (("M-o" . ace-window)))

(use-package nix-mode
:after eglot
:ensure t
:config
(setq lsp-nix-nixd-server-path "nixd"
      lsp-nix-nixd-formatting-command [ "nixfmt" ]
      lsp-nix-nixd-nixpkgs-expr "import <nixpkgs> { }"
      lsp-nix-nixd-nixos-options-expr "(builtins.getFlake \"/home/nb/nixos\").nixosConfigurations.mnd.options"
      lsp-nix-nixd-home-manager-options-expr "(builtins.getFlake \"/home/nb/nixos\").homeConfigurations.\"nb@mnd\".options"))

(use-package nix-ts-mode
  :ensure t
  :mode "\\.nix\\'")

(add-hook 'nix-ts-mode-hook
          (lambda ()
            ;; enable autocompletion with company
            (setq-local company-idle-delay 0.1)))

;; Use built-in tree-sitter modes for C/C++ (grammars come from packages.nix).
(setopt treesit-enabled-modes '(c-ts-mode c++-ts-mode))

(use-package treesit-fold
  :ensure t
  :demand t
  :config
  (global-treesit-fold-mode 1)
  :bind (:map treesit-fold-mode-map
              ("C-c f" . treesit-fold-toggle)
              ("C-c F" . treesit-fold-open-all)))

(use-package rcirc
  :commands rcirc
  :config
  (add-to-list 'rcirc-server-alist
               '("irc.oftc.net"
                 :channels ("#cat-v"))))
(use-package nerd-icons
  :ensure t)
(load-file "~/nix/emacs/acme-mouse.el")

;; theme
(use-package doom-themes
  :ensure t
  :config
  (load-theme 'doom-one t))

;; dashboard
(use-package dashboard
  :ensure t
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-startup-banner 'official)
  (setq dashboard-center-content t)
  (setq dashboard-set-navigator t)
  (setq dashboard-set-file-icons t)
  (setq dashboard-set-heading-icons t)
  (setq dashboard-items '((recents  . 5)))

  (setq initial-buffer-choice (lambda () (get-buffer-create "*dashboard*"))))

(use-package vertico
  :ensure t
  :init
  (vertico-mode)
  :custom
  (vertico-cycle t)
  (vertico-count 10)
  (vertico-resize t)
  (vertico-preselect 'prompt)
  (enable-recursive-minibuffers t)
  :config
  (setq completion-auto-help t)
  (setq completion-show-inline-help t)
  (setq completion-auto-select 'completion-at-point))

(use-package multiple-cursors
  :ensure t
  :bind (("C-S-c C-S-c" . mc/edit-lines)
         ("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-c C-<" . mc/mark-all-like-this)))

;; Language services: Eglot manages Flymake diagnostics.
(use-package eglot
  :hook ((c-mode . eglot-ensure)
         (c++-mode . eglot-ensure)
         (c-ts-mode . eglot-ensure)
         (c++-ts-mode . eglot-ensure)
         (nix-ts-mode . eglot-ensure))
  :config
  (setq eglot-sync-connect nil)
  (setq eglot-connect-timeout 30)
  (setq eglot-report-progress t)
  (setq eglot-extend-to-xref t))

(add-hook 'prog-mode-hook
          (lambda ()
            (add-hook 'before-save-hook 'eglot-format nil t)))

;; add lsps here
(with-eval-after-load 'eglot
  (dolist (mode '(((nix-mode nix-ts-mode) . ("nixd"))))
    (add-to-list 'eglot-server-programs mode)))

;; Process output tuning.
(setq read-process-output-max (* 1024 1024))

;; Scroll by the pointer's row in the event window.
(defun galaxy-brain-scroll-amount (event)
  "Return a scroll amount based on EVENT's row, or one if unavailable."
  (let* ((position (event-start event))
         (window (posn-window position))
         (coordinates (posn-x-y position)))
    (if (and (window-live-p window)
             (consp coordinates)
             (numberp (cdr coordinates)))
        (max 1 (/ (cdr coordinates)
                  (frame-char-height (window-frame window))))
      1)))

(defun my-mouse-wheel-scroll (event)
  "Scroll EVENT's window according to the pointer's row."
  (interactive "e")
  (let ((mouse-wheel-follow-mouse t)
        (mouse-wheel-scroll-amount (list (galaxy-brain-scroll-amount event))))
    (mwheel-scroll event)))

(global-set-key [wheel-up] 'my-mouse-wheel-scroll)
(global-set-key [wheel-down] 'my-mouse-wheel-scroll)

;; Package help.
(defun describe-package-at-point (package)
  "Describe PACKAGE, interactively using the symbol at point."
  (interactive (list (symbol-at-point)))
  (unless package
    (user-error "No package symbol at point"))
  (describe-package package))

(global-set-key (kbd "C-h C-p") #'describe-package-at-point)
