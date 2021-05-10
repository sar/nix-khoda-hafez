#{ config, pkgs, options, ... }:

#####
# ones I want to look at but maybe not on this server:
# https://github.com/domtronn/all-the-icons.el
# https://github.com/bcbcarl/emacs-wttrin
# https://github.com/Fuco1/clippy.el
#####
self: super: 

  myEmacsConfig = super.writeText "default.el" ''

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; use-package
(require 'package)
(package-initialize 'noactivate)
(eval-when-compile
  (require 'use-package))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; sublimity
;; https://github.com/zk-phi/sublimity
(require 'sublimity)
;; (require 'sublimity-scroll)
;; (require 'sublimity-map) ;; experimental
;; (require 'sublimity-attractive)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ansible
;; https://github.com/k1LoW/emacs-ansible
(add-hook 'yaml-mode-hook '(lambda () (ansible 1)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; emojify
;; https://github.com/iqbalansari/emacs-emojify
(use-package emojify
  :hook (after-init . global-emojify-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; elpy
;; https://github.com/jorgenschaefer/elpy
(use-package elpy
  :ensure t
  :init
  (elpy-enable))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; yaml-mode
;; https://github.com/yoshiki/yaml-mode
(require 'yaml-mode)
(add-to-list 'auto-mode-alist '("\\.yml\\'" . yaml-mode))
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; flycheck
;; https://github.com/flycheck/flycheck
(use-package flycheck
  :ensure t
  :init (global-flycheck-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; nix-mode
;; https://github.com/NixOS/nix-mode
(use-package nix-mode
  :mode "\\.nix\\'")
  
  '';

  myEmacs = pkgs.emacsWithPackages (epkgs: (with epkgs.melpaStablePackages; [
    (runCommand "default.el" {} ''
      set -x
      mkdir -p $out/share/emacs/site-lisp
      cp ${myEmacsConfig} $out/share/emacs/site-lisp/default.el
    '')
    flycheck
    yaml-mode
    nix-mode
    elpy
    ansible
    sublimity
    emojify
  ]));
