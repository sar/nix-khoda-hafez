{ config, lib, pkgs, options, ... }:

{
  boot = {
    kernelParams = [
      "console=tty0"
      "console=ttyS0,115200n8"
      "console=ttyS1,115200n8"	
      "console=ttyS2,115200n8"
    ];
    kernelModules = [
      "pl2303"  
    ];
  };
  environment = {
    systemPackages = with pkgs; [
      usbutils
    ];
  };
}