#####
# This creates emacs-brody
#####

# this worked:
# https://github.com/gsood-gaurav/nixos/blob/f2b2a0fd1444774b4ec3ad4a9f543a280ba1a4a1/nixpkgs/overlays/emacs.nix
#####
# ones I want to look at but maybe not on this server:
# https://github.com/domtronn/all-the-icons.el
# https://github.com/bcbcarl/emacs-wttrin
# https://github.com/Fuco1/clippy.el
#####
self: super: 

let
  emacs-brody = super.emacs-nox; 
  emacsWithPackages = (super.emacsPackagesGen emacs-brody).emacsWithPackages;
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
;;(use-package emojify
;;  :hook (after-init . global-emojify-mode))

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
in
{
  emacs-brody = emacsWithPackages (epkgs: (with epkgs.melpaStablePackages; [
    (super.runCommand "default.el" {} ''
      set -x
      mkdir -p $out/share/emacs/site-lisp
      cp ${myEmacsConfig} $out/share/emacs/site-lisp/default.el
    '')
    use-package
    flycheck
    yaml-mode
    nix-mode
    elpy
    ansible
    sublimity
#    emojify
  ]));
}