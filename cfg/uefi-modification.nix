{ config, lib, pkgs, options, ... }:


{
#  nixpkgs.config.allowBroken = true;
 environment = {
# qt is for uefitools which i clone from git
    systemPackages = with pkgs; [
      git
#      qt5.full
#      qt4
#      qt3
      dmidecode
      bc
      pciutils
      file
      gcc
      binutils
      efivar
      efitools
      uefitool
      flashrom
      gnumake
      cmake
      zip
    ];
  };
}