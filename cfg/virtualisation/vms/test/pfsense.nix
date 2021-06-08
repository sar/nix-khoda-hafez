{ config, lib, pkgs, ... }:
with lib;
let
  version = "2.5.1";
  pfDir = "/storage/vm/pfsense";
  iso = "pfSense-CE-${version}-RELEASE-amd64.iso";
  isoGz = "${iso}.gz";
  isoSha256 = "${isoGz}.sha256";
  awk = "${pkgs.nawk}/bin/nawk";
  wget = "${pkgs.wget}/bin/wget";
  gzip = "${pkgs.gzip}/bin/gzip";

  import = [
    ./pfsense-download.nix
    ./pfsense-img.nix
  ];
  
  buildVm = vmName: {    
    after = [
      "libvirtd.service"
      "libvirtd-pfsense-vm.service"
    ];
    requires = [
      "libvirtd.service"
      "libvirtd-pfsense-vm.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    restartIfChanged = false;

    script =
      let
        xml = pkgs.substituteAll {
          src = ./pfsense.xml;
          name = vmName;
          ovmf_q35 = "pc-q35-5.1";
          net_lan_source_dev = "pfsense-lan";
          net_lan_mac_address = "68:05:c4:20:69:21";
          net_wan_source_dev = "pfsense-wan";
          net_wan_mac_address = "68:05:c4:20:69:20";
          disk_img = "${pfDir}/pfsense.raw";
          disk_iso = "${pfDir}/${iso}";
        };

      in
        ''
          uuid="$(${getBin pkgs.libvirt}/bin/virsh domuuid '${vmName}' || true)"
          ${getBin pkgs.libvirt}/bin/virsh define <(sed "s/UUID/$uuid/" '${xml}')
          ${getBin pkgs.libvirt}/bin/virsh start '${vmName}'
        '';

    preStop = ''
        ${getBin pkgs.libvirt}/bin/virsh shutdown '${vmName}'
        let "timeout = $(date +%s) + 120"
        while [ "$(${getBin pkgs.libvirt}/bin/virsh list --name | grep --count '^${vmName}$')" -gt 0 ]; do
          if [ "$(date +%s)" -ge "$timeout" ]; then
            # Meh, we warned it...
            ${getBin pkgs.libvirt}/bin/virsh destroy '${vmName}'
          else
            # The machine is still running, let's give it some time to shut down
            sleep 0.5
          fi
        done
    '';
  };
  #getIso = callPackage download {};
in
{
  systemd.services.libvirtd-pfsense-download = downloadIsoGz "${pfDir}/${iso}";
  systemd.services.libvirtd-pfsense-extract = extractIso "${pfDir}/${isoGz}";
  systemd.services.libvirtd-pfsense-img1 = buildImg "pfsense1";
  systemd.services.libvirtd-pfsense-img2 = buildImg "pfsense2";
  systemd.services.libvirtd-pfsense-vm1 = buildVm "pfsense1";
  systemd.services.libvirtd-pfsense-vm2 = buildVm "pfsense2";
}
