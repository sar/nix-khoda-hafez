{ config, lib, pkgs, options, ... }:

{
  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    cpu = {
      amd = {
        updateMicrocode = true;
      };
    };
  };
}