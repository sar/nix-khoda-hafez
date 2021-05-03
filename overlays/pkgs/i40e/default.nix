#with import <nixpkgs> {};
{ stdenv, fetchurl, linuxPackages_latest, kmod }:
# there's some issues with this package
let
  kernel = linuxPackages_latest.kernel;
  version = "2.15.9";
in
stdenv.mkDerivation rec {
  name = "i40e-${version}-${kernel.version}";
  src = fetchurl {
    url = "mirror://sourceforge/e1000/i40e-${version}.tar.gz";
    sha256 = "1djmdr4258ymsxjn0h4f8z268vilaclidhnrznrspam7r6bfjnga";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies; 

  hardeningDisable = [ "pic" ];

  configurePhase = ''
    cd src
    makeFlagsArray+=(KSRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build INSTALL_MOD_PATH=$out MANDIR=/share/man)
    substituteInPlace common.mk --replace /sbin/depmod ${kmod}/bin/depmod
    # prevent host system kernel introspection
    substituteInPlace common.mk --replace /boot/System.map /not-exists
  '';

  meta = with stdenv.lib; {
    description = "Intel(R) Ethernet Connection XL710 Network Driver";
    homepage = "https://sourceforge.net/projects/e1000/files/i40e%20stable";
    license = licenses.gpl2;
#    priority = 20;
#    broken = versionAtLeast kernel.version "5.2";
  };




}      