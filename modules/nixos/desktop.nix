{ config, lib, pkgs, noctalia, userSettings, ... }:
{
  imports =
    [
      noctalia.nixosModules.default
    ];

  networking = {
    hostName = userSettings.hostName;
    networkmanager.enable = true;
    firewall = {
      allowedTCPPorts = [ 53317 ];
      allowedUDPPorts = [ 53317 ];
    };
  };

  services = {
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

  programs = {
    git = {
      enable = true;
      config = {
        user = {
          name  = userSettings.username;
          email = userSettings.email;
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

  users.users.${userSettings.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
  };

  fonts.packages = with pkgs; [
    maple-mono.NF-CN
  ];
}
