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
      /usr/bin
    ];
    extraRules = ''
      SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="68:05:ca:32:36:fc", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="sfp0"

      SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="68:05:ca:32:36:fd", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="sfp1"

      SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="68:05:ca:32:36:fe", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="sfp2"

      SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="68:05:ca:32:36:ff", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="sfp3"
  '';
  };

  networking.interfaces = {
    sfp0 = {
      useDHCP = false;
    };
    sfp1 = {
      useDHCP = false;
    };
    sfp2 = {
      useDHCP = false;
    };
    sfp3 = {
      useDHCP = false;
    };
  };
}