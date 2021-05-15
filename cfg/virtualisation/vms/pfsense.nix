{ config, lib, pkgs, ... }:
# SEO:
# bsd freebsd ports nixos declaritive automated edge router edge-router
# 
# somewhat ripped from the wonderful kalbasit
# https://github.com/kalbasit/soxincfg/tree/main/hosts/hades
# as I have no idea what I'm doing.
#
# Goal sumary is to have it create a pfsense VM that handles WAN + LAN (plus VPN) traffic.
# Steps:
# 0. learn nix stuff lol
# 1. download pfsense
# 2. check it against the provided sha256 file
# 3. create a raw image of specified size inside specified directory
# 4. create libvirt xml conf
# 5. Use a direct console (not IP) to run commands:
#   - install Nix from ports
#   - not sure of the other commands needed just yet
#     - have to figure out what exactly can be done from CLI in pfsense, and how
# 6. isolate cpu cores for network performance
# 7. create BSD based nix binary cache
# 8. create a way on the host that I can deploy nix to pfsense
#
#

with lib;
let
  version = "2.5.1";
  buildPfsense = vmName:
    {
      sha256sum = pkgs.fetchurl {
        url = https://www.pfsense.org/hashes/pfSense-CE-${version}-RELEASE-amd64.iso.gz.sha256;
      };
      
      iso = pkgs.fetchurl {
        url = https://nyifiles.netgate.com/mirror/downloads/pfSense-CE-${version}-RELEASE-amd64.iso.gz;
	      sha256 = sha256sum;
      };

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
in
{
  systemd.services.libvirtd-guest-pfsense = buildPfsense "pfsense";
}

