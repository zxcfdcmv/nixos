{ config, lib, pkgs, ... }:
{
  services = {
    sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true;
      openFirewall = true;
      package = pkgs.sunshine.override { cudaSupport = true; };
    };
    udev.extraRules = ''
      KERNEL=="uinput", MODE="0660", GROUP="input", SYMLINK+="uinput"
    '';
  };
  systemd.services.sunshine.serviceConfig.Environment = "LD_LIBRARY_PATH=/run/opengl-driver/lib";
}
