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
    gnome.gnome-keyring.enable = true;
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
      xdg-desktop-portal
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
        gtk3
        webkitgtk_4_1
        libsoup_3
        cairo
        pango
        gdk-pixbuf
        harfbuzz
        libappindicator-gtk3
        openssl
        dbus
      ];
    };
    droidcam.enable = true;
  };

  environment = {
    sessionVariables = {
      WLR_NO_HARDWARE_CURSORS= "1";
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "xcb";
      __GL_MaxFramesAllowed = "1";
      NIXOS_OZONE_WL = "1";
      __GL_SYNC_TO_VBLANK = "0";
      __GL_GSYNC_ALLOWED = "0";
      __GL_VRR_ALLOWED = "0";
      EDITOR = "hx";
      VISUAL = "hx";
      GTK_CSD = "0";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      SDL_IM_MODULE = "fcitx";
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
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    corefonts
  ];
}
