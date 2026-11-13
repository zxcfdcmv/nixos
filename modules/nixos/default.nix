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

  # portal 前端 (xdg-desktop-portal) 和 backend 都是 D-Bus 按需激活的 systemd
  # user unit，不需要也不应该放进 compositor 的 autostart：
  #   - 手动启动的实例不受 systemd 管理（没有 Restart、不随会话 teardown）
  #   - graphical-session.target 起来后，D-Bus 激活会自动带起它们
  # wlr.enable 会自己把 xdg-desktop-portal-wlr 加进 extraPortals，并生成配置 + drop-in。
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # 选屏 chooser 必须写死绝对路径。portal 现在是 systemd user service，
    # PATH 里只有 grim/slurp 那一小撮（没有 fuzzel），于是默认 chooser 链
    # 第一个命中的是 slurp；slurp 的全屏十字准星遮罩在 driftwm 的画布上抓不到
    # 指针，用户选不中，最后 xdg-desktop-portal-wlr 只能报 "no output found"，
    # 腾讯会议那边就表现为屏幕列表空的、对面一直转圈。
    # 以前 portal 是 driftwm 的子进程、PATH 里有 fuzzel，所以一路 fallback
    # 到 fuzzel 的文本列表才正常。
    wlr.settings.screencast = {
      chooser_type = "dmenu";
      chooser_cmd = "${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt='选择要共享的屏幕' --lines=10";
    };
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      # XDG_CURRENT_DESKTOP 未设置时的兜底。
      common.default = [ "wlr" "gtk" ];
      # driftwm 启动时会设置 XDG_CURRENT_DESKTOP=driftwm：
      # 截图/录屏走 wlroots 实现，文件选择、打印等走 gtk，
      # Secret 交给 gnome-keyring（gtk portal 不实现 Secret）。
      driftwm = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
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
