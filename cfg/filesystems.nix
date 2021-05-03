{ config, lib, pkgs, options, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      exfat
    ];
  };

  fileSystems = {
    "/" = {
      device = "rpool/safe/nixos/root";
      fsType = "zfs";
    };
    "/home" = {
      device = "rpool/safe/storage/home";
      fsType = "zfs";
    };
    "/nix" = {
      device = "rpool/local/storage/nixos/nix";
      fsType = "zfs";
    };
    "/storage/secrets" = {
      device = "rpool/safe/storage/secrets";
      fsType = "zfs";
    };
    "/storage/vm" = {
      device = "rpool/safe/storage/vm";
      fsType = "zfs";
    };

    "/storage/vm/pfsense" = {
      device = "rpool/safe/storage/vm/pfsense";
      fsType = "zfs";
    };

#    "/key" = {
#      device = "/dev/disk/by-id/usb-Kingston_DataTraveler_3.0_6C626D7C24E3F1A0691F0308-0:0-part1";
#      fsType = "vfat";
#    };
#    "/key-1" = {
#      device = "/dev/disk/by-label/key-1";
#      fsType = "vfat";
#    };
#    "/key-2" = {
#      device = "/dev/disk/by-label/key-2";
#      fsType = "vfat";
#    };    
  };
}