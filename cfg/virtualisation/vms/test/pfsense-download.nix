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

in

{
#  environment = { systemPackages = with pkgs; [ nawk ]; };

  systemd.services.libvirtd-pfsense-download = downloadIsoGz "${pfDir}/${iso}";
  systemd.services.libvirtd-pfsense-extract = extractIso "${pfDir}/${isoGz}";  
}