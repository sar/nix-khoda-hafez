{ config, lib, pkgs, ... }:
with lib;
let
  version = "2.5.1";
  pfDir = "/storage/vm/pfsense";
  iso = "pfSense-CE-${version}-RELEASE-amd64.iso";
#  iso = "pfSense-CE-memstick-serial-2.5.2-RELEASE-amd64.img";
  # i440fx or q35
  machineType = "i440fx";
  isoGz = "${iso}.gz";
  isoSha256 = "${isoGz}.sha256";
  routerName = "pfsrt";
  awk = "${pkgs.nawk}/bin/nawk";
  wget = "${pkgs.wget}/bin/wget";
  gzip = "${pkgs.gzip}/bin/gzip";
  virsh = "${getBin pkgs.libvirt}/bin/virsh";
  qemu-img = "${pkgs.qemu}/bin/qemu-img";
  q35Model = "pc-q35-5.1";
  i440fxModel = "pc-i440fx-6.0";

  # info on out-of-store manipulation
  # https://discourse.nixos.org/t/is-there-a-way-to-work-with-files-outside-nix-in-nixops/3220
  # https://discourse.nixos.org/t/java-based-emacs-package-ejc-sql-expects-write-access-to-install-directory-need-workaround/8317
  # https://discourse.nixos.org/t/unable-to-use-gzip-in-derivation-to-package-crystal-lsp-server-binary/12173/4

  # lots of this can be replaced by a service directive of some sort that only runs the service when a condition is met.
  # later, replace with template units.

  # Making it a module is what I'd prefer to do:
  # https://nixos.wiki/wiki/NixOS:extend_NixOS

  # Can't use virtio disks with q35 until freebsd 13?
  # https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=236922
  
  downloadIsoGz = isoNameGz: {
    description = "Download the specified pfSense ISO file version.";
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
      "pfsense-extract.service"
#      "pfsense-vm-01.service"
#      "pfsense-vm-02.service"
#      "setPermissions.service"
    ];
    requires = [
      "network.target"
      "libvirtd.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "no";
    };
    restartIfChanged = true;
    script = ''
      if ! [[ -f "${pfDir}/${isoGz}" ]]
      then
        set -x
        printf "\nDownloading ${isoGz}\n"
        ${wget} -q https://nyifiles.netgate.com/mirror/downloads/${isoGz} -O ${pfDir}/${isoGz} &
        printf "\nDownloaded and placed in ${pfDir}/${isoGz}\n"
        set +x
      elif [[ -f "${pfDir}/${isoGz}" ]]
      then
        printf "\nAlready exists in ${pfDir}/${isoGz}\n"
      else
        printf "\nDon't know what's going on. Check ${pfDir}\n"
        exit 1
      fi

      if ! [[ -f "${pfDir}/${isoSha256}" ]]
      then
        printf "\nDownloading ${isoSha256}\n"
        ${wget} -q https://www.pfsense.org/hashes/${isoSha256} -O ${pfDir}/${isoSha256} &
        printf "\nDownloaded and placed in ${pfDir}/${isoSha256}\n"
      elif [[ -f "${pfDir}/${isoSha256}" ]]
      then
        printf "\nAlready exists in ${pfDir}/${isoSha256}\n"
      else
        printf "\nDon't know what's going on. Check ${pfDir}\n"
        exit 1
      fi
      wait
      if [[ "$(sha256sum ${pfDir}/${isoGz} | ${awk} '{print $1}')" == "$(cat ${pfDir}/${isoSha256} | ${awk} '{print $4}')" ]]
      then
        printf "\nSHA256 sums match.\n"
        exit 0
      else
        printf "\nSHA256 sums do not match.\n"
        exit 1
      fi
      exit 1
    '';
  };
  
  extractIso = isoLocation: {
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
#      "pfsense-download.service"
    ];
    before = [
      "pfsense-vm-01.service"
      "pfsense-vm-02.service"
#      "setPermissions.service"      
    ];
    requires = [
      "network.target"
      "libvirtd.service"
      "pfsense-download.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "no";    
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
    
  createDisk = rawLocation: vmName: vmNumber: diskType: {
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
      "pfsense-${vmName}-${vmNumber}.service"
#      "setPermissions.service"
    ];
    requires = [
      "network.target"
      "libvirtd.service"
    ];    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "no";
    };
    restartIfChanged = true;
    
    script = ''
      if [[ -f "${rawLocation}/${vmName}-${vmNumber}.${diskType}" ]]
      then
        printf "\n\nDisk '${rawLocation}/${vmName}-${vmNumber}.${diskType}' already exists."
        exit 0
      else
        ${virsh} pool-create-as ${vmName} dir --target ${rawLocation} || echo true
        ${virsh} vol-create-as ${vmName} '${vmName}-${vmNumber}.${diskType}' 20G --format ${diskType}
        if ! [[ -f "${rawLocation}/${vmName}-${vmNumber}.${diskType}" ]]
        then
          printf "\n\nSomething happened and ${rawLocation}/${vmName}-${vmNumber}.${diskType} was not created."
          exit 1
        fi
        exit 0
      fi
      exit 1
    '';
  };

  buildvm = rawLocation: vmName: vmNumber: diskType: {
    description = "Create and turn on the VM with virsh.";
    wantedBy = [ "multi-user.target" ];
    bindsTo = [
      "network.target"
      "libvirtd.service"
#      "pfsense-download.service"
#      "pfsense-extract.service"
#      "pfsense-disk-01.service"
#      "pfsense-disk-02.service"
    ];    
    after = [
      "network.target"
      "libvirtd.service"
      "pfsense-download.service"
      "pfsense-extract.service"
      "pfsense-disk-${vmNumber}.service"
#      "pfsense-disk-02.service"
#      "setPermissions.service"
    ];
    requires = [
      "network.target"
      "libvirtd.service"
      "pfsense-download.service"
      "pfsense-extract.service"
      "pfsense-disk-${vmNumber}.service"
#      "pfsense-disk-02.service"
#      "setPermissions.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    restartIfChanged = true;

    script =
      let
        xml = pkgs.substituteAll {
          src = ./. + "/pfsense-${machineType}.xml";
          name = vmName + "-" + vmNumber;
          ovmf_q35 = q35Model;
          i440fx = i440fxModel;

#          net_int_source_dev = "int-${vmName}";
#          net_int_mac_address = "68:05:c4:20:69:23";
#          net_int_target_dev = "int-${vmName}-${vmNumber}";
          
          net_int = ''  <interface type="bridge">
    <mac address="68:05:c4:20:69:23"/>
    <source bridge="int-${vmName}"/>
    <target dev="int-${vmName}-${vmNumber}"/>
    <virtualport type="openvswitch"/>
    <model type="virtio"/>
  </interface>'';

#          net_man_source_dev = "man-${vmName}";
#          net_man_mac_address = "68:05:c4:20:69:22";
#          net_man_target_dev = "man-${vmName}-${vmNumber}";
          
          net_man = ''  <interface type="bridge">
    <mac address="68:05:c4:20:69:22"/>
    <source bridge="man-${vmName}"/>
    <target dev="man-${vmName}-${vmNumber}"/>
    <virtualport type="openvswitch"/>
    <model type="virtio"/>
  </interface>'';

#          net_lan_source_dev = "lan-${vmName}";
#          net_lan_mac_address = "68:05:c4:20:69:21";
#          net_lan_target_dev = "lan-${vmName}-${vmNumber}";
          
          net_lan = ''  <interface type="bridge">
    <mac address="68:05:c4:20:69:21"/>
    <source bridge="lan-${vmName}"/>
    <target dev="lan-${vmName}-${vmNumber}"/>
    <virtualport type="openvswitch"/>
    <model type="virtio"/>
  </interface>'';

#          net_wan_source_dev = "wan-${vmName}";
#          net_wan_mac_address = "68:05:c4:20:69:20";
#          net_wan_target_dev = "wan-${vmName}-${vmNumber}";

          net_wan = ''  <interface type="bridge">
    <mac address="68:05:c4:20:69:20"/>
    <source bridge="wan-${vmName}"/>
    <target dev="wan-${vmName}-${vmNumber}"/>
    <virtualport type="openvswitch"/>
    <model type="virtio"/>
  </interface>'';
          
          disk_img = "${rawLocation}/${vmName}-${vmNumber}.${diskType}";
          disk_iso = "${rawLocation}/${iso}";
        };
      in
        ''
	  cat ${xml}
          uuid="$(${virsh} domuuid '${vmName}-${vmNumber}' || true)"
          ${virsh} define <(sed "s/UUID/$uuid/" '${xml}')
          ${virsh} reset '${vmName}-${vmNumber}' || echo true
          ${virsh} start '${vmName}-${vmNumber}'
        '';

    preStop = ''
        ${virsh} destroy '${vmName}-${vmNumber}'
        ${virsh} undefine --nvram --managed-save --storage ${rawLocation}/${vmName}-${vmNumber}.${diskType} --domain ${vmName}-${vmNumber}
        let "timeout = $(date +%s) + 120"
        while [ "$(${virsh} list --name | grep --count '^${vmName}-${vmNumber}$')" -gt 0 ]; do
          if [ "$(date +%s)" -ge "$timeout" ]; then
            # Meh, we warned it...
            ${virsh} destroy '${vmName}-${vmNumber}'
            ${virsh} undefine --nvram --managed-save --storage ${rawLocation}/${vmName}-${vmNumber}.${diskType} --domain ${vmName}-${vmNumber}
            rm -rf /storage/vms/pfsense/${vmName}-${vmNumber}.raw
          else
            # The machine is still running, let's give it some time to shut down
            sleep 0.5
          fi
        done
    '';
  };
in

{
  systemd.services.pfsense-download = downloadIsoGz "${pfDir}/${iso}";
  systemd.services.pfsense-extract = extractIso "${pfDir}/${isoGz}";
  systemd.services.pfsense-disk-01 = createDisk "${pfDir}" "${routerName}" "01" "raw";
  systemd.services.pfsense-disk-02 = createDisk "${pfDir}" "${routerName}" "02" "raw";
  systemd.services.pfsense-vm-01 = buildvm "${pfDir}" "${routerName}" "01" "raw";
  systemd.services.pfsense-vm-02 = buildvm "${pfDir}" "${routerName}" "02" "raw";
}
