{ config, pkgs, options, ... }:
{

  nix.nixPath = options.nix.nixPath.default ++ [ "nixpkgs-overlays=/etc/nixos/overlays/" ];
    

  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./overlays
      ./cfg.nix
    ];
    # the boot section is all requred for encrypted zfs root
  boot = {

#    blacklistedKernelModules = [
#      ""
#    ];

    zfs = {
      devNodes = "/dev/disk/by-path";
      forceImportRoot = true;
      forceImportAll = true;
      requestEncryptionCredentials = [ "rpool/safe" ];
    };
    
    supportedFilesystems= [ "zfs" ];
    loader = {
      efi.canTouchEfiVariables = false;

      grub = {
        zfsSupport = true;
        copyKernels = true;
        enable = true;
        efiSupport = true;
        device = "nodev";
	efiInstallAsRemovable = true;
	useOSProber = true;
        mirroredBoots = [
	  {
	    devices = [ "/dev/disk/by-id/ata-Samsung_SSD_870_QVO_1TB_S5VSNG0NA25723Z" ];
            path = "/boot-fallback";
	  }
        ];
	
	memtest86 = {
	  enable = true;
#	  params = [];
        };
	
	extraEntries = ''
	  menuentry 'UEFI Firmware Settings' {
	    fwsetup
	  }

	'';
      };
      
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = with pkgs; [
      neofetch
      htop
      git
      curl
      wget
      tcpdump
      unzip
      p7zip
      unrar
      iptables
      ranger
      w3m
      nox
      lm_sensors
      iotop
      dmidecode
      nix-bash-completions
      tshark
      bc
      pciutils
      file
      gcc
      binutils
      efivar
      efitools
      uefitool
      flashrom
      gnumake
      cmake
      zip
      usbutils
      libsysfs
#      i40e
    ];  
  };
  
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?
  nixpkgs.config.allowUnfree = true;
  nix.autoOptimiseStore = true;
  nix.gc.automatic = false;
}
