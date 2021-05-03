{ config, lib, pkgs, ... }:                                                                       
#with builtins;
#with lib.strings;
#with lib.attrsets;
#let
# This gets a list of all '.nix' files in a given folder (excludes '.nix~')
#nixInFolder = dir: map (x: dir + "/" + x) (attrNames (filterAttrs (name: _: hasSuffix ".nix" name) (readDir dir)));
#in
{
  #  imports = nixInFolder "/etc/nixos/cfg/net-interfaces/intel-x710";
  environment = {
    systemPackages = with pkgs; [
      dpdk
      openssl
    ];
  };

  # openvswitch requires python2.7 for everything, which seems to end up picking up openssl 1.0.2.
  # didn't want to deal with figuring out what exactly was pulling it in and fixing it.
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.0.2u"
  ];

  virtualisation.vswitch = {
    enable = true;
  };

  # my motherboard doesn't support sriov

  # vswitches is an attribute set
  networking = {
    vswitches = {
      pfsense-wan = {
        interfaces = {
          sfp3 = { };
        };	
        extraOvsctlCmds = ''
          set bridge pfsense-wan other-config:hwaddr=68:05:c4:20:69:10
        '';
      };
      pfsense-lan = {
        interfaces = {
          sfp0 = { };
        };	
        extraOvsctlCmds = ''
          set bridge pfsense-lan other-config:hwaddr=68:05:c4:20:69:11
        '';
      };
    };

    interfaces = {
      pfsense-wan = {
        useDHCP = false;
#	macAddress = "68:05:c4:20:69:00";
      };
      pfsense-lan = {
        useDHCP = false;
#	macAddress = "68:05:c4:20:69:01";
      };
      ovs-system = {
        useDHCP = false;
      };
    };
  };

  
  # useful commands:
  # udevadm info /sys/class/net/enp3s0
  # journalctl -ex | grep udev
#  services.udev = {
#    path = [
#      /bin
#      /usr/bin
#    ];
#    extraRules = ''
#  '';
#  };
}