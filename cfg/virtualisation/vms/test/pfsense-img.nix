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
  # ya I don't know if this works yet honestly

  # what i have here is based on what I found here:
  # http://johnmercier.com/blog/2017/12-28-adding-jbake-to-nixpkgs.html
  # which has a section that makes more sense than anything in the docs.
  # that said, it still doesn't work exactly

  # going to have to look into this for out-of-store manipulation
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
      else
        printf "\nSHA256 sums do not match.\n"
        exit 1
      fi
    '';
  };
  
  extractIso = isoLocation: {    
    after = [
      "libvirtd.service"
      "libvirtd-pfsense-download.service"
    ];
    before = [ "libvirtd-pfsense-vm.service" ];
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
        ${gzip} --synchronous -v -d "${isoLocation}"
      else
        printf "\n\nISO '${isoLocation}' does not exist."
      fi
    '';    

  };

  buildvm = vmName: {    
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
#  environment = { systemPackages = with pkgs; [ nawk ]; };

  systemd.services.libvirtd-pfsense-download = downloadIsoGz "${pfDir}/${iso}";
  systemd.services.libvirtd-pfsense-extract = extractIso "${pfDir}/${isoGz}";  
  systemd.services.libvirtd-pfsense-vm = buildvm "pfsense";
}