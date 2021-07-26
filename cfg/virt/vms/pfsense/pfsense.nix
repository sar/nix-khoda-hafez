{ config, lib, pkgs, ... }:
with lib;
let
  functions = "../functions.nix";
  cfg = config.services.router;
  awk = "${pkgs.nawk}/bin/nawk";
  wget = "${pkgs.wget}/bin/wget";
  gzip = "${pkgs.gzip}/bin/gzip";
  virsh = "${getBin pkgs.libvirt}/bin/virsh";
  qemu-img = "${pkgs.qemu}/bin/qemu-img";
  
in {
  options.services.router = {

    enable = mkEnableOption "Build the router";
    
    name = mkOption {
      type = types.str;
      default = "router";
      description = ''
        Base name for the devices.
      '';
    };

    numberOfVms = mkOption {
      type = types.int;
      default = 1;
      description = ''
         Number of VMs to make. Default is 1.
      '';
    };
    
    generalStorage = mkOption {
      type = types.str;
      default = "/storage/vms/${cfg.name}";
    };

    isoFileLocation = mkOption {
      type = types.str;
      default = "${cfg.location}/${cfg.router}";
      description = ''Defaults to ${cfg.location}/${cfg.router}'';
    };

    isoFileName = mkOption {
      types = types.str;
      description = ''
        Name of ISO file. No default.
      '';
    };

    isoURL = mkOption {
      type = types.str;
      description = ''
        URL to download your installation ISO from.
      '';
    };
    
    ###########################
    # VM options
    ###########################
    
    vmModel = mkOption {
      type = types.str;
      description = ''
        q35 or i440fx
        q35 has issues with virtio drivers in BSD.
      '';
    };

    vmCpuNum = mkOption {
      type = types.str;
      default = 4;
      description = ''
        Number of cores to use. Default is 4.
      '';
    };

    vmMemory = mkOption {
      type = types.str;
      default = "4194304";
      description = ''
        In KiB. Default is 4194304.
      '';
    };

    vmWanInterface = mkOption {
      type = types.str;
      default = "null";
      description = ''
        Interface to use for WAN.
      '';
    };

    vmLanInterface = mkOption {
      type = types.str;
      default = "null";
      description = ''
        Interface to use for LAN.
      '';
    };
    
    isoName = mkOption {
      type = types.str;
      description = ''
        Manditory.
      '';
    };
    
    config = {
      


    };
  }
