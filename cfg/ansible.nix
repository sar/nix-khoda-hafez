{ config, lib, pkgs, options, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      ansible
      ansible-lint
    ];
  };
}