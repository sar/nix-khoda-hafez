{ config, lib, pkgs, ... }:
with builtins;
with lib.strings;
with lib.attrsets;
let
# This gets a list of all '.nix' files in a given folder (excludes '.nix~')
nixInFolder = dir: map (x: dir + "/" + x) (attrNames (filterAttrs (name: _: hasSuffix ".nix" name) (readDir dir)));
in
{
  imports = nixInFolder "/etc/nixos/cfg/virtualisation/vm";
  environment = {
    systemPackages = with pkgs; [
      libvirt
      qemu
      OVMF-CSM
      OVMF
      pciutils
    ];
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemuOvmf = true;
      extraConfig = "\n
        unix_sock_group = \"libvirt\"\n
	unix_sock_rw_perms = \"0770\"";
    };
  };
  
  networking.firewall = {
    allowedTCPPorts = [
      5900 #vnc
      5901 #spice
    ];
    allowedUDPPorts = [
      5900 #vnc
      5901 #spice
    ];    
  };

  users.groups = {
    libvirt = {
      members = [ "brody" ];
    };
  };

}
