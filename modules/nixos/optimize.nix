{ config, lib, pkgs, nix-cachyos-kernel, ... }:
{
  nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ];

  # boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
  services = {
    # ananicy = {
    #   enable = true;
    #   package = pkgs.ananicy-cpp;
    #   rulesProvider = pkgs.ananicy-rules-cachyos;
    # };

    system76-scheduler = {
      enable = true;
      settings = {
        processScheduler = {
          # 前台窗口自动提升优先级
          foregroundBoost.enable = true;
          # PipeWire 音频线程优化
          pipewireBoost.enable = true;
        };
      };
    };
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };
    scx = {
      enable = true;
      scheduler = "scx_lavd";
      package = pkgs.scx.full;
    };

    earlyoom = {
      enable = true;
      freeMemThreshold = 8;
      freeSwapThreshold = 5;
      extraArgs = [
        "-g"
        "--avoid" "^(vxwm|river|kwm|pipewire|Xwayland|systemd)$"
        "--prefer" "^(electron|chrome|firefox|edge|nix-build|cc1plus|nh|rustc)$"
      ];
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "lz4";      # 速度快、CPU 占用低
    memoryPercent = 50;     # 最多用 50% RAM 做压缩 swap
    priority = 100;         # 优先使用 zram，其次才是磁盘 swap
  };
}
