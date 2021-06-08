{ config, lib, pkgs, ... }:
with lib;
let
  version = "2.5.1";
  pfDir = "/storage/vm/pfsense";
  iso = "pfSense-CE-${version}-RELEASE-amd64.iso";
  isoGz = "${iso}.gz";
  isoSha256 = "${isoGz}.sha256";
  routerName = "pfsrt";
  awk = "${pkgs.nawk}/bin/nawk";
  wget = "${pkgs.wget}/bin/wget";
  gzip = "${pkgs.gzip}/bin/gzip";
  virsh = "${getBin pkgs.libvirt}/bin/virsh";
  qemu-img = "${pkgs.qemu}/bin/qemu-img";

  # info on out-of-store manipulation
  # https://discourse.nixos.org/t/is-there-a-way-to-work-with-files-outside-nix-in-nixops/3220
  # https://discourse.nixos.org/t/java-based-emacs-package-ejc-sql-expects-write-access-to-install-directory-need-workaround/8317
  # https://discourse.nixos.org/t/unable-to-use-gzip-in-derivation-to-package-crystal-lsp-server-binary/12173/4
  downloadIsoGz = isoNameGz: {    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    restartIfChanged = true;
    script = ''
    # lots of this can be replaced by a service directive of some sort that only runs the service when a condition is met.
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
    after = [
      "libvirtd.service"
      "libvirtd-pfsense-download.service"
    ];
    before = [
      "libvirtd-pfsense-vm-01.service"
      "libvirtd-pfsense-vm-02.service"
    ];
    requires = [
      "libvirtd.service"
      "libvirtd-pfsense-download.service"
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

  createDisk = rawLocation: {    
    after = [
      "libvirtd.service"
    ];
    before = [
      "libvirtd-pfsense-vm-01.service"
      "libvirtd-pfsense-vm-02.service"
    ];
    requires = [
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
        #/storage/vm/pfsense/pfsense1.raw 20G
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

  buildvm = vmName: {    
    after = [
      "libvirtd.service"
      "libvirtd-pfsense-download.service"
      "libvirtd-pfsense-extract.service"
      "libvirtd-pfsense-disk-01.service"
      "libvirtd-pfsense-disk-02.service"
    ];
    requires = [
      "libvirtd.service"
      "libvirtd-pfsense-download.service"
      "libvirtd-pfsense-extract.service"
      "libvirtd-pfsense-disk-01.service"
      "libvirtd-pfsense-disk-02.service"
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
          disk_img = "${pfDir}/${vmName}.raw";
          disk_iso = "${pfDir}/${iso}";
        };

      in
        ''
          uuid="$(${virsh} domuuid '${vmName}' || true)"
          ${virsh} define <(sed "s/UUID/$uuid/" '${xml}')
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
  #getIso = callPackage download {};
in

{
#  environment = { systemPackages = with pkgs; [ nawk ]; };

  systemd.services.libvirtd-pfsense-download = downloadIsoGz "${pfDir}/${iso}";
  systemd.services.libvirtd-pfsense-extract = extractIso "${pfDir}/${isoGz}";
  systemd.services.libvirtd-pfsense-disk-01 = createDisk "${pfDir}/${routerName}-01";
  systemd.services.libvirtd-pfsense-disk-02 = createDisk "${pfDir}/${routerName}-02";
  systemd.services.libvirtd-pfsense-vm-01 = buildvm "${routerName}-01";
  systemd.services.libvirtd-pfsense-vm-02 = buildvm "${routerName}-02";
}
