{ ... }:
{
  vmCreateHost = vmName: {
    description = "Create and turn on the VM with virsh.";
    wantedBy = [ "multi-user.target" ];
    bindsTo = [
      "network.target"
      "libvirtd.service"
      "pfsense-download.service"
      "pfsense-extract.service"
      "pfsense-disk-01.service"
      "pfsense-disk-02.service"
    ];    
    after = [
      "network.target"
      "libvirtd.service"
      "pfsense-download.service"
      "pfsense-extract.service"
      "pfsense-disk-01.service"
      "pfsense-disk-02.service"
      "setPermissions.service"
    ];
    requires = [
      "network.target"
      "libvirtd.service"
      "pfsense-download.service"
      "pfsense-extract.service"
      "pfsense-disk-01.service"
      "pfsense-disk-02.service"
      "setPermissions.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    restartIfChanged = false;

    script =
      let
        xml = pkgs.substituteAll {
          src = "/etc/nixos/cfg/virt/vms/pfsense.xml";
          name = vmName;
          ovmf_q35 = q35Model;
          i440fx = i440fxModel;
          net_lan_source_dev = "pfsense-lan";
          net_lan_mac_address = "68:05:c4:20:69:21";
          net_wan_source_dev = "pfsense-wan";
          net_wan_mac_address = "68:05:c4:20:69:20";
          disk_img = "${pfDir}/${vmName}.raw";
          disk_iso = "${pfDir}/${iso}";
        };

      in
        ''
          uuid="$(${virsh} domuuid '${vmName}' || true)"
          ${virsh} define <(sed "s/UUID/$uuid/" '${xml}')
          ${virsh} start '${vmName}'
        '';

  };
}
