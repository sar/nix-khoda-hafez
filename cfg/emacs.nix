{ config, pkgs, options, ... }:
#let
#  myEmacs = import /etc/nixos/overlays/pkgs/emacs/default.nix-one-i-want;
#  myEmacs = import /etc/nixos/overlays/pkgs/emacs/default.nix-from-the-docs;  
#in
{
  services.emacs = {
    install = true;
    enable = true;
    defaultEditor = true;
    package = pkgs.emacs-nox;
  };
  
#  environment = {
#    systemPackages = with pkgs; [
#     myEmacs
#    ];
#  };

  nixpkgs.overlays = [ (import /etc/nixos/overlays/pkgs/emacs/default.nix) ];
}
