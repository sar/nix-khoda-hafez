{ config, lib, pkgs, options, ... }:

{
  services.udev.extraRules = ''
    =="0000:29:00.0", SUBSYSTEM=="pci", DRIVER=="i40e", ATTR{sriov_numvfs}="32", ATTR{sriov_drivers_autoprobe}="0"
    KERNEL=="0000:29:00.0", SUBSYSTEM=="pci", DRIVER=="i40e", ATTR{sriov_numvfs}="32", ATTR{sriov_drivers_autoprobe}="0"
  '';
 environment = {
    systemPackages = with pkgs; [
      iproute
      ethtool
    ];
  };
}