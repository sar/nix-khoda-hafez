{ config, lib, pkgs, ... }:                                                                       
with builtins;
with lib.strings;
with lib.attrsets;
let
# This gets a list of all '.nix' files in a given folder (excludes '.nix~')
nixInFolder = dir: map (x: dir + "/" + x) (attrNames (filterAttrs (name: _: hasSuffix ".nix" name) (readDir dir)));
in
{
#  imports = nixInFolder "/etc/nixos/cfg/net-interfaces/intel-x710";

  # useful commands:
  # udevadm info /sys/class/net/enp3s0
  # journalctl -ex | grep udev
  services.udev = {
    path = [
      /bin
#      /sbin
      /usr/bin
    ];
    extraRules = ''
      ACTION=="add", \
      SUBSYSTEM=="net", \
      ENV{PRODUCT}=="8086/1572", \     
      ENV{ID_NET_DRIVER}=="i40e", \
      ATTR{device/sriov_numvfs}="4", \
      ATTR{device/sriov_drivers_autoprobe}="1"
  '';
  };
}