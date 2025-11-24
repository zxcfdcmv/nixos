{ config, lib, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  time.timeZone = "Asia/Shanghai";
  i18n = {
    defaultLocale = "zh_CN.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" "zh_CN.UTF-8/UTF-8" ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "zxcfdcmv";
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd '${pkgs.niri}/bin/niri --session'";
      };
    };
  };

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  hardware.graphics = {
    enable = true;
  };

  programs = {
    niri.enable = true;
    git = {
      enable = true;
      config = {
        user = {
          name  = "zxcfdcmv";
          email = "zxcfdcmv@foxmail.com";
        };
      };
    };
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  
  environment = {
    sessionVariables = {
      LC_ALL = "en_US.UTF-8";
    };
    systemPackages = with pkgs; [
      helix
      wget
      curl
      xwayland-satellite
      wl-clipboard
    ];
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      substituters = [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];
    };
  };

  users.users.zxcfdcmv = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  fonts.packages = with pkgs; [
    noto-fonts-cjk-sans
  ];
  system.stateVersion = "25.11";
}

