{ config, lib, pkgs, ... }:
{
#  environment =	{
#    systemPackages = with pkgs; [
#    ];
#  };

# nix shouldn't handle secrets:
# ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_builder-$(hostname -s) -N ''
# cp "/root/.ssh/id_builder-$(hostname -s).pub" "/etc/nixos/cfg/ssh-keys/id_builder-$(hostname -s).pub"
# ssh-copy-id -i /root/.ssh/id_builder-$(hostname -s) root@[otherhost]

  nix = {
    buildMachines = [
      {
        hostName = "khoda-hafez";
        system = "x86_64-linux";
        speedFactor = 1;
        maxJobs = 16;                                                                                                               
        sshUser = "root";
        sshKey = "/root/.ssh/id_builder-bidaya";
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        mandatoryFeatures = [ ];
      }
      {
        hostName = "bidaya";
        system = "x86_64-linux";
        speedFactor = 2;
        maxJobs = 8;
        sshUser = "root";
        sshKey = "/root/.ssh/id_builder-khoda-hafez";
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        mandatoryFeatures = [ ];
      }      
    ];
    distributedBuilds = true;
    trustedUsers = [ "root" ];
  };
  programs = {
    ssh = {
      extraConfig = ''
        Host khoda-hafez
          HostName 192.168.69.203
          Port 22
          User root

          # Prevent using ssh-agent or another keyfile, useful for testing
          IdentitiesOnly yes
          IdentityFile /root/.ssh/id_builder-bidaya

        Host bidaya
          HostName 192.168.69.202
          Port 22
          User root
	  
          # Prevent using ssh-agent or another keyfile, useful for testing
          IdentitiesOnly yes
          IdentityFile /root/.ssh/id_builder-khoda-hafez

      '';
    };
  };
  users.users = {
    root = {
      openssh.authorizedKeys.keyFiles = [
        /etc/nixos/cfg/ssh-keys/id_builder-khoda-hafez.pub
        /etc/nixos/cfg/ssh-keys/id_builder-bidaya.pub
      ];
    };
  };
}
