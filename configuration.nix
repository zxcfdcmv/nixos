{ config, lib, pkgs, noctalia, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      noctalia.nixosModules.default
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
    firewall = {
      allowedTCPPorts = [ 53317 ];
      allowedUDPPorts = [ 53317 ];
    };
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

  services = {
    xserver = {
      videoDrivers = [ "nvidia" ];
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    power-profiles-daemon.enable = true;
    upower.enable = true;
    greetd = {
      enable = true;
      settings.default_session.command = ''
        ${pkgs.tuigreet}/bin/tuigreet \
          --cmd "${pkgs.niri}/bin/niri-session" \
          --theme "dark" \
          --greet-align center \
          --time \
          --time-format "%A, %d %B %Y %H:%M:%S" \
          --remember \
      '';
    };
    noctalia-shell.enable = true;
    dae = {
      enable = true;

      config = ''
        global {
          lan_interface: auto
          wan_interface: auto
          log_level: info
        }

        subscription {
          'https://gh-proxy.com/https://raw.githubusercontent.com/chengaopan/AutoMergePublicNodes/master/list.meta.yml'
          'https://proxy.v2gh.com/https://raw.githubusercontent.com/Pawdroid/Free-servers/main/sub'
          'https://gh-proxy.com/raw.githubusercontent.com/snakem982/proxypool/main/source/clash-meta.yaml'
        }

        group {
          proxy {
            policy: min_moving_avg
          }
        }

        routing {
          dip(geoip:private) -> direct
          dip(geoip:cn) -> direct
          fallback: proxy
        }
      '';
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
        default = "wlr";
      };
    };
  };

  hardware = {
    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = false;
      powerManagement.enable = true;
      nvidiaPersistenced = true;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    bluetooth.enable = true;
  };

  programs = {
    git = {
      enable = true;
      config = {
        user = {
          name  = "zxcfdcmv";
          email = "zxcfdcmv@foxmail.com";
        };
      };
    };

    niri.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;

      extraCompatPackages = with pkgs; [ proton-ge-bin ];
    };
  };
  
  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      _GL_GSYNC_ALLOWED = "0";
      _GL_VRR_ALLOWED = "0";
      EDITOR = "hx";
      VISUAL = "hx";
    };
    systemPackages = with pkgs; [
      helix
      wget
      curl
    ];
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      substituters = [
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        "https://cache.nixos.org"
      ];
    };
    gc = {
      automatic    = true;
      dates        = "weekly";
      options      = "--delete-older-than 7d";
    };
  };

  users.users.zxcfdcmv = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
    pam.services.greetd = {
      startSession = true;
    };
  };

  fonts.packages = with pkgs; [
    maple-mono.NF-CN
  ];
  system.stateVersion = "25.11";
}

