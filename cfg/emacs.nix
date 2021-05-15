{ config, pkgs, options, ... }:
{
  services.emacs = {
    install = true;
    enable = true;
    defaultEditor = true;
    package = pkgs.emacs-nox;
  };
  
  environment = {
    systemPackages = with pkgs; [
     emacs-brody
    ];
  };

  # brings in emacs-brody overlay for my config.
  nixpkgs.overlays = [ (import /etc/nixos/overlays/emacs.nix) ];
}
