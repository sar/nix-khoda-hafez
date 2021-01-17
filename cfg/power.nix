{ config, lib, pkgs, options, ... }:

{
 powerManagement = {
   enable = true;
#   cpufreq = {
#     max = ;
#     min = ;
#   };
   cpuFreqGovernor = "ondemand";
 };
# environment = {
#    systemPackages = with pkgs; [
#      iproute
#      ethtool
#    ];
#  };
}