{ config, lib, pkgs, ... }:
with builtins;
with lib.strings;
with lib.attrsets;
let
# This gets a list of all '.nix' files in a given folder (excludes '.nix~')
nixInFolder = dir: map (x: dir + "/" + x) (attrNames (filterAttrs (name: _: hasSuffix ".nix" name) (readDir dir)));
in
{
  imports = nixInFolder "/etc/nixos/cfg/virt";
  services = {
    irqbalance.enable = false;
  };
  
  boot = {
    kernelParams = [
      "pci=realloc"
      "pci=assign-busses"
      "amd_iommu=on"
      "iommu=on"      
      # "pci=nocrs" # causes usb xhci_* drivers to not function properly
#      "pci_pt_e820_access=on"
#     "topoext"
#      "kvm_amd.npt=1"
#      "kvm_amd.nested=1"
#     "hugepages=8192"
#      "efi=runtime"
#      "efi_no_storage_paranoia"
    ];
    
    kernelModules = [
      "kvm_amd"
      "amd_iommu"
#      "vfio"
#      "vfio_pci"
#      "vfio_virqfd"
#      "vfio_iommu_type1"
#      "efivarfs"
    ];
  };

}
