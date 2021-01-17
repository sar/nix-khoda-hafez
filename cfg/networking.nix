{ config, lib, pkgs, options, ... }:
with builtins;
with lib.strings;
with lib.attrsets;
let
# This gets a list of all '.nix' files in a given folder (excludes '.nix~')
nixInFolder = dir: map (x: dir + "/" + x) (attrNames (filterAttrs (name: _: hasSuffix ".nix" name) (readDir dir)));
in
{
  imports = nixInFolder "/etc/nixos/cfg/net-interfaces";
  networking = {
    hostName = "khoda-hafez";
    hostId = "beef0dad";
    useDHCP = true;
    nameservers = [ "192.168.69.1" "8.8.8.8" "1.1.1.1" ];
    firewall = {
      enable = false;
#      allowedTCPPorts = [      ];
#      allowedUDPPorts = [      ];
     allowPing = true;
    };
    iproute2 = {
      enable = true;
    };
    bridges = {
      bridge5 = {
        interfaces = [ "enp6s0" ];
      };
#      bridge0 = {
#        interfaces = [ "enp10s0f0" ];
#      };
    };
    interfaces = {
      bridge5 = {
        macAddress = "2c:f0:5d:42:06:90";
        useDHCP = false;
        ipv4 = {
          addresses = [
            { address = "192.168.69.203"; prefixLength = 24; }
	  ];
        };
      };
#      bridge0 = {
#       enp10s0f0 = {
#        macAddress = "68:05:c4:20:69:00";
#        useDHCP = false;
#        ipv4 = {
#          addresses = [
#            { address = "192.168.69.205"; prefixLength = 24; }
#	  ];
#        };
#      };
#      wlp7s0.useDHCP = true;
    };
    defaultGateway = {
      address = "192.168.69.1";
      interface = "bridge5";
      metric = 100;
    };
#    localCommands = '' ''    
  };
  environment = {
    systemPackages = with pkgs; [
      iproute
      ethtool
    ];
  };
}