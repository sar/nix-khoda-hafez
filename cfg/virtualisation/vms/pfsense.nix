{ config, lib, pkgs, unzip, ... }:
with lib;
let
  version = "2.5.1";
  # ya I don't know if this works yet honestly

#  download = {
#    pfsense = rec {
#      iso = builtins.fetchurl {
#        url = "https://nyifiles.netgate.com/mirror/downloads/pfSense-CE-${version}-RELEASE-amd64.iso.gz";
#        sha256 = "be79df534558e6a73f7be2e8643c6ed01580e40b79b255f9bd8e8cca6471fee7";
#      };
#    };
#  };

  # what i have here is based on what I found here:
  # http://johnmercier.com/blog/2017/12-28-adding-jbake-to-nixpkgs.html
  # which has a section that makes more sense than anything in the docs.
  download = {stdenv, fetchurl, unzip}:
    pkgs.stdenv.mkDerivation {
      name = "pfsense-${version}";
      src = builtins.fetchurl {
        url = "https://nyifiles.netgate.com/mirror/downloads/pfSense-CE-${version}-RELEASE-amd64.iso.gz";
        sha256 = "be79df534558e6a73f7be2e8643c6ed01580e40b79b255f9bd8e8cca6471fee7";
      };
      buildInputs = [pkgs.unzip];
      phases = [ "unpackPhase" "installPhase" ];
      unpackPhase = ''
        ls -lah
        unzip ${src}  
        ls -lah           
      '';  
      installPhase = ''
        mv ${name} $out/storage/vms/pfsense/
      '';          
    };


  
  buildPfsense = vmName: {
    
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    restartIfChanged = true;

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
          disk_img = "/storage/vm/pfsense/pfsense.raw";
          disk_iso = "/storage/vm/pfsense/pfSense-CE-${version}-RELEASE-amd64.iso";
#          disk_iso = "${download}";
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
  callPackage = download {};
  systemd.services.libvirtd-guest-pfsense = buildPfsense "pfsense";
}
    

