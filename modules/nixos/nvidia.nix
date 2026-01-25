{ config, lib, pkgs, ... }:
{
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];
  
  services = {
    xserver = {
      videoDrivers = [ "nvidia" ];
    };
  };

  hardware = {
    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = false;
      powerManagement.enable = true;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}
