{ config, lib, pkgs, options, ... }:

{
  services.emacs = {
    install = true;
    enable = true;
    defaultEditor = true;
    package = pkgs.emacs-nox;
  };
}
