{ config, lib, pkgs, ... }:
{
  users = {
    mutableUsers = true;
    users = {
      brody = {
        name = "brody";
        isNormalUser = true;
        description = "Biggest Admin";
	shell = pkgs.bash;
        uid = 1000;
	createHome = true;
	home = "/home/brody";
	initialPassword = "initialpw";
	extraGroups = [ "wheel" ];
        subUidRanges = [{
	  startUid = 100000;
	  count = 65536;
        }];
        subGidRanges = [{
	  startGid = 100000;
	  count = 65536;
	}];
      };
    };
    groups = {
      brody = { gid = 1000; };
    };
  };
}
