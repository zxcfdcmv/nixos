{ config, lib, pkgs, ... }:
{
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    # "initcall_blacklist=acpi_cpufreq_init"
    # "amd_pstate=active"
  ];
  
  services = {
    xserver = {
      videoDrivers = [ "nvidia" ];
    };
  };

  hardware = {
    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      powerManagement = {
        enable = true;
        finegrained = false;
      };
      open = false;
      # package = config.boot.kernelPackages.nvidiaPackages.stable;
      package = config.boot.kernelPackages.nvidia_x11;
    };
  };

  environment.etc = {
    "nvidia/nvidia-application-profiles-rc.d/50-niri-fix.json" = {
      text = ''
        {
          "rules": [
            {
              "pattern": {
                "feature": "procname",
                "matches": "niri"
              },
              "profile": "Limit Free Buffer Pool On Wayland Compositors"
            }
          ],
          "profiles": [
            {
              "name": "Limit Free Buffer Pool On Wayland Compositors",
              "settings": [
                {
                  "key": "GLVidHeapReuseRatio",
                  "value": 0
                }
              ]
            }
          ]
        }
      '';
    };
  };  
}
