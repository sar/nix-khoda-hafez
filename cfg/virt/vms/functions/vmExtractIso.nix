{ ... }:
{
  vmExtractIso = isoLocation: {
    description = "Extract the downloaded ISO file.";
    wantedBy = [ "multi-user.target" ];
    after = [
      "network.target"
      "libvirtd.service"
      "pfsense-download.service"
    ];
    bindsTo = [
      "network.target"
      "libvirtd.service"
      "pfsense-download.service"
    ];
    before = [
      "pfsense-vm-01.service"
      "pfsense-vm-02.service"
      "setPermissions.service"      
    ];
    requires = [
      "network.target"
      "libvirtd.service"
      "pfsense-download.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    restartIfChanged = true;
    script = ''
      if [[ -f "${isoLocation}" ]]
      then
        ${gzip} --synchronous -v -d "${isoLocation}" || true
        exit 0
      else
        printf "\n\nISO '${isoLocation}' does not exist."
        exit 1
      fi
      exit 1
    '';    

  };

}
