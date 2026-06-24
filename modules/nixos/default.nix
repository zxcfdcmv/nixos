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
    upower.enable = true;
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
      river = {
        default = [ "wlr" "gtk" ];
      };
      common = {
        default = [ "wlr" "gtk" ];
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
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        fontconfig
        freetype
        icu
        libx11 libxext libxcursor libxrandr libxi libice libsm
        libGL
        zlib
        glib
        SDL2 SDL2_image SDL2_ttf SDL2_mixer
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
      __GL_SYNC_TO_VBLANK = "0";
      __GL_GSYNC_ALLOWED = "0";
      __GL_VRR_ALLOWED = "0";
      EDITOR = "hx";
      VISUAL = "hx";
      GTK_CSD = "0";
    };
    systemPackages = with pkgs; [
      helix
      wget
      curl
    ];
    etc = {
      "opt/edge/policies/managed/policies.json".text = ''
        {
          "NewTabPageLocation": "about:blank",
          "NewTabPageContentEnabled": false,
          "NewTabPageQuickLinksEnabled": false,
          "NewTabPageAllowedBackgroundTypes": 3,
          "NewTabPageAppLauncherEnabled": false,
          "NewTabPageBingChatEnabled": false,
          "NewTabPageHideDefaultTopSites": true,

          "HubsSidebarEnabled": false,
          "CopilotPageContext": false,
          "CopilotAddressBarSuggestionsEnabled": false,
          "GenAILocalFoundationalModelSettings": 0,
          "Microsoft365CopilotChatIconEnabled": false,

          "EdgeShoppingAssistantEnabled": false,
          "ShowMicrosoftRewards": false,
          "ShowRecommendationsEnabled": false,
          "PromotionalTabsEnabled": false,
          "QuickSearchShowMiniMenu": false,
          "VisualSearchEnabled": false,

          "EdgeCollectionsEnabled": false,
          "EdgeWorkspacesEnabled": false,
          "WhatsNewPageForEntraProfilesEnabled": false,
          "MicrosoftEdgeInsiderPromotionEnabled": false,
          "GuidedSwitchEnabled": false,

          "PersonalizationReportingEnabled": false,
          "PersonalizeTopSitesInCustomizeSidebarEnabled": false,
          "EdgeAssetDeliveryServiceEnabled": false,

          "PasswordManagerEnabled": false,
          "AutofillAddressEnabled": false,
          "AutofillCreditCardEnabled": false,
          "AutofillMembershipsEnabled": false,
          "PaymentMethodQueryEnabled": false,

          "HideFirstRunExperience": true,
          "AutoImportAtFirstRun": 4,
          "BrowserGuestModeEnabled": false,

          "AllowGamesMenu": false,
          "PictureInPictureOverlayEnabled": false,
          "QRCodeGeneratorEnabled": false,
          "ReadAloudEnabled": false,
          "RemoteDebuggingAllowed": false,
          "ShowAcrobatSubscriptionButton": false,
          "PinBrowserEssentialsToolbarButton": false,
          "UserFeedbackAllowed": false,

          "AlternateErrorPagesEnabled": false,
          "ResolveNavigationErrorsUseWebService": false,
          "NetworkPredictionOptions": 2,
          "QuicAllowed": false,
          "SearchSuggestEnabled": false,
          "DefaultSearchProviderContextMenuAccessAllowed": false,

          "ConfigureDoNotTrack": true,
          "WebRtcLocalhostIpHandling": "disable_non_proxied_udp",
          "SitePerProcess": true
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
