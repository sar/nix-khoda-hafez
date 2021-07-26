{ config, lib, pkgs, ... }:
with builtins;
with lib.strings;
with lib.attrsets;
let
# This gets a list of all '.nix' files in a given folder (excludes '.nix~')
nixInFolder = dir: map (x: dir + "/" + x) (attrNames (filterAttrs (name: _: hasSuffix ".nix" name) (readDir dir)));
in
{
#  imports = nixInFolder "/etc/nixos/cfg/virt/lxc-containers";
  environment = {
    systemPackages = with pkgs; [
      lxc
      lxcfs
      lxd
      distrobuilder
      pciutils
      apparmor-kernel-patches
    ];
  };

  virtualisation = {
    lxd = {
      enable = false;
      zfsSupport = true;
      recommendedSysctlSettings = true;
      lxcPackage = pkgs.lxc;
    };

    lxc = {
      enable = false;
      lxcfs.enable = false;
      systemConfig = "";
      defaultConfig = "";
      usernetConfig = "";
    };
  };
  
  networking.firewall = {
    allowedTCPPorts = [
    ];
    allowedUDPPorts = [
    ];    
  };

  users.groups = {
#    libvirt = {
#      members = [ "brody" ];
#    };
  };

}
