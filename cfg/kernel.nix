{ config, lib, pkgs, options, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages;
  };
  #/usr/src/linux-$(uname -r)
  environment = {
    systemPackages = with pkgs; [
#      linuxHeaders
      linuxPackages_latest.kernel.dev
#      linuxPackages.kernel.dev      
    ];
  };

  boot.kernelParams = [ "nomodeset" ];
}