{ config, lib, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  nixpkgs.config.allowUnfree = true;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "nvidia-drm.modeset=1" ];
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  time.timeZone = "Asia/Shanghai";
  i18n = {
    defaultLocale = "zh_CN.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" "zh_CN.UTF-8/UTF-8" ];
  };

  services = {
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    greetd = {
      enable = true;
      settings = {
        default_session = {
          user = "zxcfdcmv";
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd '${pkgs.niri}/bin/niri --session'";
        };
      };
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default-session = [ "wlr" "gtk" ];
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

  systemd.user.extraConfig = ''
    DefaultEnvironment="XDG_CURRENT_DESKTOP=niri"
  '';

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
  
  environment = {
    sessionVariables = {
      LC_ALL = "en_US.UTF-8";
      EDITOR = "hx";
      VISUAL = "hx";
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

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
    pam.services.greetd.enableGnomeKeyring = true;
    rtkit.enable = true;
  };

  fonts.packages = with pkgs; [
    maple-mono.NF-CN
  ];
  system.stateVersion = "25.11";
}

