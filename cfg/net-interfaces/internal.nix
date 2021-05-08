{ config, lib, pkgs, ... }:                                                                       
with builtins;
with lib.strings;
with lib.attrsets;
let
# This gets a list of all '.nix' files in a given folder (excludes '.nix~')
nixInFolder = dir: map (x: dir + "/" + x) (attrNames (filterAttrs (name: _: hasSuffix ".nix" name) (readDir dir)));
in
{
  # useful commands:
  # udevadm info /sys/class/net/enp3s0
  # journalctl -ex | grep udev
  services.udev = {
    path = [
      /bin
      /usr/bin
    ];
    extraRules = ''
      SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="2c:f0:5d:55:6b:10", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="net0"
  '';
  };

  networking = {
    bridges.br-net0.interfaces = [ "net0" ];
    interfaces = {
      net0 = {
        useDHCP = true;
      };
    
      br-net0 = {
        macAddress = "2c:f0:5d:42:06:90";
        useDHCP = true;
        ipv4 = {
          addresses = [
            { address = "192.168.69.203"; prefixLength = 24; }
          ];
        };
      };
      
    };
  };
  
}