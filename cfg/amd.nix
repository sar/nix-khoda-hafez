{ config, lib, pkgs, options, ... }:

{
  hardware.cpu.amd.updateMicrocode = true;
# environment = {
#    systemPackages = with pkgs; [
#    ];
#  };
}