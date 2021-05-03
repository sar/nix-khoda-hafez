{ config, lib, pkgs, options, ... }:

{
  boot = {
    kernelParams = [
      "console=tty0"
      "console=ttyUSB0,921600n8"
    ];
    kernelModules = [
      "pl2303"  
    ];
#    kernelPatches = [
#      {
#      }
#    ];
  };
  environment = {
    systemPackages = with pkgs; [
      usbutils
      screen
      setserial
#      busybox
    ];
  };
  services.mingetty = {
    serialSpeed = [
      921600
    ];
#    loginOptions = "ttyUSB0";
  };
  systemd.services."serial-getty@ttyUSB0" = {
    enable = true;
    wantedBy = [ "getty.target" ];
    script = "agetty -m -L 921600 ttyUSB0 vt100";
#    scriptArgs
    serviceConfig.Restart = "always";
#    reloadIfChanged = true;   
  };
  console = {
    earlySetup = true;
    extraTTYs = [ "ttyUSB0" ];
  };
  services.journald = {
    console = "/dev/ttyUSB0";
  };
#    extraconfig = [
  services.syslogd.tty = "/dev/ttyUSB0";
}