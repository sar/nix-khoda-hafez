{ config, lib, pkgs, options, ... }:
{
  environment =	{
    systemPackages = with pkgs; [
      openssh
      sshfs
    ];
  };
  services = {
    openssh = {
      enable = true;
      openFirewall = true;
      ports = [ 22 ];
      allowSFTP = true;      
      permitRootLogin = "no";
      passwordAuthentication = false;
      forwardX11 = true;
    };
  };
  users.users = {
    brody = {
      openssh.authorizedKeys.keyFiles = [ /etc/nixos/cfg/ssh-keys/brody.pub ];
    };
  };
}