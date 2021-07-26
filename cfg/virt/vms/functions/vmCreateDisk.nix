{ ... }:
{
  vmCreateDisk = rawLocation: {
    description = "Create the .raw file used to store the VM OS.";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "libvirtd.service"
    ];
    bindsTo = [
      "network.target"
      "libvirtd.service"
    ];    
    before = [
      "setPermissions.service"
    ];
    requires = [
      "network.target"
      "libvirtd.service"
    ];    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    restartIfChanged = true;
    script = ''
      if [[ -f "${rawLocation}.raw" ]]
      then
        printf "\n\nDisk '${rawLocation}.raw' already exists."
        exit 0
      else
        ${qemu-img} create -f raw ${rawLocation}.raw 20G 
        if ! [[ -f "${rawLocation}.raw" ]]
        then
          printf "\n\nSomething happened and ${rawLocation}.raw was not created."
          exit 1
        fi
        exit 0
      fi
      exit 1
    '';    
  };
}
