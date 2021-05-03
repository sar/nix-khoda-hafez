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
 boot = {
   extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
   blacklistedKernelModules = [
     "k10temp"
   ];
 };
# environment = {
#    systemPackages = with pkgs; [
#    ];
#  };
}