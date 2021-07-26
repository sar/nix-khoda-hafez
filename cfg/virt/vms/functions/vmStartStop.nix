{ ... }:
{
  buildvm = vmName: {
    description = "Create and turn on the VM with virsh.";
    wantedBy = [ "multi-user.target" ];
    bindsTo = [
      "network.target"
      "libvirtd.service"
    ];    
    after = [
      "network.target"
      "libvirtd.service"
    ];
    requires = [
      "network.target"
      "libvirtd.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    restartIfChanged = false;

    script = ''
          ${virsh} start '${vmName}'
        '';

    preStop = ''
        ${virsh} shutdown '${vmName}'
        let "timeout = $(date +%s) + 120"
        while [ "$(${virsh} list --name | grep --count '^${vmName}$')" -gt 0 ]; do
          if [ "$(date +%s)" -ge "$timeout" ]; then
            # Meh, we warned it...
            ${virsh} destroy '${vmName}'
          else
            # The machine is still running, let's give it some time to shut down
            sleep 0.5
          fi
        done
    '';
  };
}
