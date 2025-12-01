{ config, lib, pkgs, ... }:
let  
  # 下载并清理 GitHub 加速 hosts  
  githubHostsRaw = builtins.readFile (pkgs.fetchurl {  
    url = "https://hosts.gitcdn.top/hosts.txt";  
    sha256 = "sha256-YLGbkLxFIbd3YGlQSh2Ykfarbr5sCoBkKavCFQ2T+qg=";  # ← 替换为真实 hash 后稳定  
  });  
  
  # 过滤注释和空行，生成纯 hosts 条目  
  githubHosts = lib.concatStringsSep "\n" (  
    lib.filter (line: line != "" && !(lib.hasPrefix "#" line)) (  
      lib.splitString "\n" githubHostsRaw  
    )  
  );  
in  
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
    # 追加 GitHub 加速 hosts 
    extraHosts = githubHosts;
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
  };

  fonts.packages = with pkgs; [
    maple-mono.NF-CN
  ];
  system.stateVersion = "25.11";
}

