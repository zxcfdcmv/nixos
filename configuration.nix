{ config, lib, pkgs, nix-cachyos-kernel, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ./modules/nixos/nvidia.nix
      ./modules/nixos/desktop.nix
      # ./modules/nixos/sunshine.nix
      ./modules/nixos/proxy.nix
      ./modules/nixos/input-remapper.nix
    ];

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [ nix-cachyos-kernel.overlays.pinned ]; 
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    # kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
  };

  time.timeZone = "Asia/Shanghai";
  i18n = {
    defaultLocale = "zh_CN.UTF-8";
    extraLocaleSettings = {
      LC_MESSAGES = "en_US.UTF-8";
      LC_ADDRESS = "zh_CN.UTF-8";
      LC_IDENTIFICATION = "zh_CN.UTF-8";
      LC_MEASUREMENT = "zh_CN.UTF-8";
      LC_MONETARY = "zh_CN.UTF-8";
      LC_NAME = "zh_CN.UTF-8";
      LC_NUMERIC = "zh_CN.UTF-8";
      LC_PAPER = "zh_CN.UTF-8";
      LC_TELEPHONE = "zh_CN.UTF-8";
      LC_TIME = "zh_CN.UTF-8";
    };
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    bluetooth.enable = true;
  };

  nix = {
    settings = {
      trusted-users = [ "zxcfdcmv" ];
      builders-use-substitutes = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      substituters = [
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        "https://cache.nixos.org"
        "https://attic.xuyh0120.win/lantian"
        "https://cache.garnix.io"
      ];
      trusted-public-keys = [
        "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
        "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      ];
    };
    gc = {
      automatic    = true;
      dates        = "weekly";
      options      = "--delete-older-than 7d";
    };
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };

  system.stateVersion = "25.11";
}

