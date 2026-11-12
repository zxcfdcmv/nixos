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
      wireplumber.enable = true;
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
    wlr.enable = true;
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
    # droidcam.enable = true;

    localsend = {
      enable = true;
      openFirewall = true;
    };
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
  };

  environment = {
    sessionVariables = {
      WLR_NO_HARDWARE_CURSORS= "1";
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland,xcb";
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
    extraGroups = [ "wheel" "networkmanager" "video" "input" "docker"];
  };

  fonts = {
    fontDir.enable = true; 
    fontconfig = {
      enable = true;
      includeUserConf = true;
      antialias = true;
      hinting.enable = true;
      hinting.style = "slight";
      subpixel.rgba = "rgb";
      subpixel.lcdfilter = "default";
      localConf = ''
        <match target="pattern">
          <test qual="any" name="family"><string>emoji</string></test>
          <edit name="family" mode="assign" binding="same"><string>Noto Color Emoji</string></edit>
        </match>
      '';
      defaultFonts = {
        sansSerif = [ "Noto Sans CJK SC" "Source Han Sans SC" ];
        serif = [ "Noto Serif CJK SC" "Source Han Serif SC" ];
        monospace = [ "Maple Mono NF CN" "Noto Sans Mono CJK SC" ];
      };
    };

    packages = with pkgs; [
      maple-mono.NF-CN
      noto-fonts-color-emoji
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      corefonts
      vista-fonts
      vista-fonts-chs
    ];
  };
}
