{ config, lib, pkgs, ... }:
with lib;
let
#  version = "2.5.1";
  pfDir = "/storage/vm/pfsense";
#  iso = "pfSense-CE-2.5.2-RELEASE-amd64.iso";
  iso = "pfSense-CE-memstick-serial-2.5.2-RELEASE-amd64.img";
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
  ovs-vsctl = "${pkgs.openvswitch}/bin/ovs-vsctl";
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
    
  createDisk = vmName: vmNumber: diskType: rawLocation: {
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


  createNet = vmNetName: {
    description = "Create the ${vmNetName} network used for the VM.";
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
#      "pfsense-${vmName}-${vmNumber}.service"
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
    
    script =
      let
        xml = pkgs.substituteAll {
          src = ./. + "/network.xml";
          text = ''<network>
  <name>${vmNetName}</name>
  <forward mode="bridge"/>
  <bridge name="${vmNetName}"/>
</network>'';
        };
      in
        ''
	      cat ${xml}
        ${virsh} net-define <(cat '${xml}' || true) || true
        ${virsh} net-autostart ${vmNetName} || true
        ${virsh} net-start ${vmNetName} || true
    '';
  };

  
  buildvm = vmName: vmNumber: diskType: rawLocation: {
    description = "Create and turn on the VM with virsh.";
    wantedBy = [ "multi-user.target" ];
    bindsTo = [
      "network.target"
      "libvirtd.service"
    ];    
    after = [
      "network.target"
      "libvirtd.service"
      "pfsense-download.service"
      "pfsense-extract.service"
      "pfsense-disk-${vmNumber}.service"
    ];
    requires = [
      "network.target"
      "libvirtd.service"
      "pfsense-download.service"
      "pfsense-extract.service"
      "pfsense-disk-${vmNumber}.service"
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

          net_int = ''  <interface type="bridge">
      <mac address="68:${vmNumber}:c4:20:69:23"/>
      <source bridge="int-${vmName}"/>
      <target dev="int-${vmName}-${vmNumber}"/>
      <virtualport type="openvswitch"/>
      <model type="virtio"/>
    </interface>'';

          net_man = ''  <interface type="bridge">
      <mac address="68:${vmNumber}:c4:20:69:22"/>
      <source bridge="man-${vmName}"/>
      <target dev="man-${vmName}-${vmNumber}"/>
      <virtualport type="openvswitch"/>
      <model type="virtio"/>
    </interface>'';

          net_lan = ''  <interface type="bridge">
      <mac address="68:${vmNumber}:c4:20:69:21"/>
      <source bridge="lan-${vmName}"/>
      <target dev="lan-${vmName}-${vmNumber}"/>
      <virtualport type="openvswitch"/>
      <model type="virtio"/>
    </interface>'';

          net_wan = ''  <interface type="bridge">
      <mac address="68:${vmNumber}:c4:20:69:20"/>
      <source bridge="wan-${vmName}"/>
      <target dev="wan-${vmName}-${vmNumber}"/>
      <virtualport type="openvswitch"/>
      <model type="virtio"/>
    </interface>'';

          disk_primary = ''  <disk type="file" device="disk">
      <driver name="qemu" type="${diskType}"/>
      <source file="${rawLocation}/${vmName}-${vmNumber}.${diskType}"/>
      <target dev="vda" bus="virtio"/>
      <boot order="1"/>
      <address type="pci"/>
    </disk>'';

          disk_installer =''  <disk type="file" device="disk">
      <driver name="qemu" type="raw"/>
      <source file="${rawLocation}/${iso}"/>
      <target dev="vdb" bus="virtio"/>
      <readonly/>
      <boot order="2"/>
      <address type="pci"/>
    </disk>'';

#          disk_installer =''  <disk type="file" device="cdrom">
#      <driver name="qemu" type="iso"/>
#      <source file="${rawLocation}/${iso}"/>
#      <target dev="sdb" bus="virtio"/>
#      <readonly/>
#      <boot order="2"/>
#      <address type="pci"/>
#    </disk>'';

        };
      in
        ''
          ${ovs-vsctl} add-port man-pfsrt lan-pfsrt-${vmNumber}
          ${ovs-vsctl} add-port man-pfsrt wan-pfsrt-${vmNumber}
          ${ovs-vsctl} add-port man-pfsrt man-pfsrt-${vmNumber}
          ${ovs-vsctl} add-port man-pfsrt int-pfsrt-${vmNumber}
          uuid="$(${virsh} domuuid '${vmName}-${vmNumber}' || true)"
          ${virsh} define <(sed "s/UUID/$uuid/" '${xml}')
          ${virsh} reset '${vmName}-${vmNumber}' || echo true
          ${virsh} start '${vmName}-${vmNumber}'
        '';

    preStop = ''
        ${virsh} destroy '${vmName}-${vmNumber}' || true
        ${virsh} undefine --nvram --managed-save --storage ${rawLocation}/${vmName}-${vmNumber}.${diskType} --domain ${vmName}-${vmNumber} || true
        let "timeout = $(date +%s) + 120"
        while [ "$(${virsh} list --name | grep --count '^${vmName}-${vmNumber}$')" -gt 0 ]; do
          if [ "$(date +%s)" -ge "$timeout" ]; then
            # Meh, we warned it...
            ${virsh} destroy '${vmName}-${vmNumber}' || true
            ${virsh} undefine --nvram --managed-save --storage ${rawLocation}/${vmName}-${vmNumber}.${diskType} --domain ${vmName}-${vmNumber} || true
            rm -rf /storage/vms/pfsense/${vmName}-${vmNumber}.raw || true
          else
            # The machine is still running, let's give it some time to shut down
            sleep 0.5
          fi
        done
    '';
  };

  # predictable dhcp lease for management interfaces
  manDhcpLease = vmName: vmNumber: {
    ethernetAddress = "68:${vmNumber}:c4:20:69:22";
    hostName = "${vmName}-${vmNumber}";
    ipAddress = "10.69.4.1${vmNumber}";
  };
  

    
in

{
  systemd.services.pfsense-download = downloadIsoGz "${pfDir}/${iso}";
  systemd.services.pfsense-extract = extractIso "${pfDir}/${isoGz}";
  systemd.services.pfsense-disk-01 = createDisk "${routerName}" "01" "raw" "${pfDir}";
  systemd.services.pfsense-disk-02 = createDisk "${routerName}" "02" "raw" "${pfDir}";
#  systemd.services."int-${routerName}" = createNet "int-${routerName}";
#  systemd.services."man-${routerName}" = createNet "man-${routerName}";  
#  systemd.services."lan-${routerName}" = createNet "lan-${routerName}";
#  systemd.services."wan-${routerName}" = createNet "wan-${routerName}";
  systemd.services.pfsense-vm-01 = buildvm "${routerName}" "01" "raw" "${pfDir}";
  systemd.services.pfsense-vm-02 = buildvm "${routerName}" "02" "raw" "${pfDir}";

  services.dhcpd4 = {
    enable = true;
    interfaces = [ "man-pfsrt" ];
    authoritative = true;
    extraConfig = ''
      option subnet-mask 255.255.255.0;
      option broadcast-address 10.69.4.255;
      option domain-name-servers 8.8.8.8;
      subnet 10.69.4.0 netmask 255.255.255.0 {
        range 10.69.4.0 10.69.4.254;
      }
    '';
    machines = let
      vm1 = manDhcpLease "${routerName}" "01";
      vm2 = manDhcpLease "${routerName}" "02";
    in
      [ vm1 vm2 ];
  };

  

#  printf "vt100\n" > /dev/pts/0
#  printf "\n" > /dev/pts/0
#  printf "\n" > /dev/pts/0
#  printf "\n" > /dev/pts/0
#  printf "\n" > /dev/pts/0
#  printf 'S' > /dev/pts/0
#  printf "\n" > /dev/pts/0
#  printf '\b\b' > /dev/pts/0
#  printf '4g' > /dev/pts/0
#  printf '\t' > /dev/pts/0
#  printf "\n" > /dev/pts/0
#  printf '^[1B' > /dev/pts/0
#  printf "\n" > /dev/pts/0
#  printf "\n" > /dev/pts/0
#  printf " " > /dev/pts/0
#  printf "\n" > /dev/pts/0
#  printf "\t" > /dev/pts/0
#  printf "\n" > /dev/pts/0
#  printf "\t" > /dev/pts/0
#  printf "\n" > /dev/pts/0
#
#  # reboot
#  
#  printf "n\n" > /dev/pts/0
#  printf "vtnet3\n" > /dev/pts/0 # wan interface
#  printf "\n" > /dev/pts/0  
#  printf "y\n" > /dev/pts/0
#  
#  # reboot
#  
#  printf "8\n" > /dev/pts/0

}
