{ config, lib, pkgs, gzip, ... }:
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
  # that said, it still doesn't work exactly

  # going to have to look into this for out-of-store manipulation
  # https://discourse.nixos.org/t/is-there-a-way-to-work-with-files-outside-nix-in-nixops/3220
  # https://discourse.nixos.org/t/java-based-emacs-package-ejc-sql-expects-write-access-to-install-directory-need-workaround/8317
  # https://discourse.nixos.org/t/unable-to-use-gzip-in-derivation-to-package-crystal-lsp-server-binary/12173/4
  
  download = pkgs.stdenv.mkDerivation {
    name = "pfsense-${version}";
    pname = "$name";
    version = "2.5.1";    
    src = pkgs.fetchzip {
      url = ''https://nyifiles.netgate.com/mirror/downloads/pfSense-CE-${version}-RELEASE-amd64.iso.gz'';
      sha256 = "be79df534558e6a73f7be2e8643c6ed01580e40b79b255f9bd8e8cca6471fee7";
      downloadToTemp = true;
      postFetch =
    ''
      echo $TMPDIR
      ls -lah $TMPDIR
      unpackDir="$TMPDIR/unpack"
      mkdir "$unpackDir"
      cd "$unpackDir"
      renamed="$TMPDIR/pfSense-CE-${version}-RELEASE-amd64.iso.gz"
      echo downloadedFile renamed
      echo "$downloadedFile" "$renamed"
      mv "$downloadedFile" "$renamed"
      gzip -d "$renamed"
    '' + ''
      echo unpackDir
      echo "$unpackDir"
      fn=$(cd "$unpackDir" && echo *)
      if [ -f "$unpackDir/$fn" ]; then
        mkdir $out
      fi
      echo fn out
      echo "$fn" "$out"
      mv "$unpackDir/$fn" "$out"
    '' + ''
      $extraPostFetch
    '' + ''
      chmod 755 "$out"
      ls $TMPDIR
    '';
    };
#    phases = [ "buildPhase" "unpackPhase" "installPhase" ];    
#    buildInputs = [pkgs.unzip];
#    unpackPhase = ''unzip $src'';
#    installPhase = ''mv $name $out/storage/vms/pfsense/'';
  }
  };

   d = pkgs.stdenv.mkDerivation {
     name = "pfsense-${version}";
     pname = "$name";
     version = "2.5.1";    
     src = pkgs.fetchurl {
       url = ''https://nyifiles.netgate.com/mirror/downloads/pfSense-CE-${version}-RELEASE-amd64.iso.gz'';
       sha256 = "be79df534558e6a73f7be2e8643c6ed01580e40b79b255f9bd8e8cca6471fee7";
       postFetch = ''
         echo $TMPDIR
         ls -lah $TMPDIR
         unpackDir="$TMPDIR/unpack"
         mkdir "$unpackDir"
         cd "$unpackDir"
         renamed="$TMPDIR/pfSense-CE-${version}-RELEASE-amd64.iso.gz"
         echo downloadedFile renamed
         echo "$downloadedFile" "$renamed"
         mv "$downloadedFile" "$renamed"
         gzip -d "$renamed"
       '';
     };
     phases = [ "buildPhase" ]; # "unpackPhase" "installPhase" ];    
     buildInputs = [pkgs.gzip];
     #unpackPhase = ''gzip -d $src'';
     #installPhase = ''ls -lahr'';
     buildPhase = ''gzip -d $src'';
   }
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
#          disk_iso = "/storage/vm/pfsense/pfSense-CE-${version}-RELEASE-amd64.iso";
          disk_iso = "${builtins.toString download}";
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
#  callpackage download {};
  #callPackage = download {};
  systemd.services.libvirtd-guest-pfsense = buildPfsense "pfsense";
}
    

