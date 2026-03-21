{ config, lib, pkgs, userSettings, ... }:
{
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
  };

  systemd.services.rfkill-unblock-bluetooth = {
    description = "Unblock Bluetooth on boot";
    after = [ "basic.target" ];
    before = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
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
    gamemode.enable = true;

    gamescope = {
      enable = true;
      capSysNice = false;
    };

    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        freetype
        SDL2
        SDL2_image
        SDL2_ttf
        SDL2_mixer
        libGL
        zlib
        glib
      ];
    };   
  };

  environment = {
    sessionVariables = {
      WLR_NO_HARDWARE_CURSORS= "1";
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland;xcb";
      __GL_MaxFramesAllowed = "1";
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
    etc = {
      "opt/edge/policies/managed/policies.json".text = ''
        {
          "HubsSidebarEnabled": false,
          "EdgeShoppingAssistantEnabled": false,
          "AllowGamesMenu": false,
          "SearchSuggestEnabled": false,
          "PromotionalTabsEnabled": false,
          "NewTabPageContentEnabled": false,
          "NewTabPageQuickLinksEnabled": false,
          "NewTabPageAllowedBackgroundTypes": 3,
          "EdgeCollectionsEnabled": false,
          "UserFeedbackAllowed": false,
          "EdgeAssetDeliveryServiceEnabled": false,
          "ConfigureDoNotTrack": true,
    
          "HideFirstRunExperience": true,
          "AlternateErrorPagesEnabled": false,
          "PaymentMethodQueryEnabled": false,

          "PasswordManagerEnabled": false,
          "AutofillAddressEnabled": false,
          "AutofillCreditCardEnabled": false
        }
      '';
    };
  };

  users.users.${userSettings.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
  };

  fonts.packages = with pkgs; [
    maple-mono.NF-CN
    noto-fonts-color-emoji
  ];
}
