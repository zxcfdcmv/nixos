# home.nix
{ config, pkgs, lib, inputs, userSettings, mark-shot, purple, ... }:
{
  imports = [
    ./modules/hm/bash.nix
    ./modules/hm/terminal.nix
    ./modules/hm/fuzzel.nix
    ./modules/hm/input.nix              # 框架
    ./modules/hm/input-xiaohe.nix       # 输入方案
    ./modules/ai/ai.nix
    ./modules/ai/opencode.nix
#     ./modules/ai/dsh.nix
    ./modules/hm/proxy.nix
    ./modules/games/cdda.nix
    # ./modules/hm/qutebrowser.nix
    ./modules/hm/email.nix
    ./modules/hm/mint_notag.nix
    ./modules/hm/fireaxe.nix
    ./modules/hm/mpv.nix
    ./modules/hm/crosshair.nix
    ./modules/hm/gh.nix
    ./modules/hm/obsidian.nix
    ./modules/hm/pure_live.nix
    # ./modules/hm/fresh-editor.nix
    ./modules/hm/herdr.nix

    # scripts
    ./modules/scripts/scripts.nix
    ./modules/scripts/sts.nix
    ./modules/scripts/jts.nix
  ];

  home = {
    stateVersion = "25.11";
    username = userSettings.username;
    homeDirectory = "/home/${userSettings.username}";

    pointerCursor = {
      enable = true;
      gtk.enable = true;
      x11.enable = true;
      name = "Bibata-Modern-Ice";
      size = 24;
      package = pkgs.bibata-cursors;
    };
    sessionVariables = {
      XCURSOR_SIZE = "24";
      XCURSOR_THEME = "Bibata-Modern-Ice";
      NH_FLAKE = "${userSettings.dotfilesDir}";
    };

    packages = with pkgs; [
      # 基础
      ## 命令行工具
      ripgrep bat eza fd dust
      p7zip unzip unrar jq poppler imagemagick ffmpegthumbnailer
      xwayland-satellite
      wl-clipboard-rs
      nvd nix-output-monitor
      nil nixd
      openssl
      xdg-user-dirs
      ## md查看器
      glow
      # 系统工具
      ## 音量
      pulsemixer
      ## 蓝牙
      bluetuith
      ## 亮度
      brightnessctl
      ## 网络 nmtui

      # 对比工具
      # diffoscope icdiff
      kdiff3

      # x11
      dmenu-rs-enable-plugins
      hsetroot xclip xcursor-themes
      xdotool

      # 应用
      microsoft-edge
      (prismlauncher.override {
        jdks = [ zulu21 zulu25 ];
      })
      teamspeak6-client
      # localsend
      croc
      heroic
      # ayugram-desktop
      piliplus
      ## 键盘映射
      kanata
      wemeet
      ## office
      # anki

      ## 截图
      # ksnip
      snipaste # x11
      mark-shot.packages.${pkgs.stdenv.hostPlatform.system}.default # wayland
      ## 剪切板
      copyq gnupg
      gopeed
      # stremio-linux-shell ffmpeg

      rclone

      dbeaver-bin
      # purple.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    file = {
      ".snipaste/config.ini" = {
        source = config.lib.file.mkOutOfStoreSymlink "${userSettings.dotfilesDir}/assets/snipaste.ini";
        force = true;
      };
    };

    activation = {
      copyFontsForOnlyoffice = lib.hm.dag.entryAfter ["writeBoundary"] ''
        TARGET_DIR="$HOME/.local/share/fonts/onlyoffice-real"
        mkdir -p "$TARGET_DIR"
        chmod -R u+w "$TARGET_DIR" 2>/dev/null || true
        [ -n "$TARGET_DIR" ] && rm -rf "$TARGET_DIR"/*

        cp -L ${pkgs.vista-fonts-chs}/share/fonts/truetype/* "$TARGET_DIR/" 2>/dev/null || true
        cp -L ${pkgs.maple-mono.NF-CN}/share/fonts/truetype/* "$TARGET_DIR/" 2>/dev/null || true
        cp -L ${pkgs.corefonts}/share/fonts/truetype/* "$TARGET_DIR/" 2>/dev/null || true
        cp -L ${pkgs.vista-fonts}/share/fonts/truetype/* "$TARGET_DIR/" 2>/dev/null || true
        cp -L ${pkgs.noto-fonts-color-emoji}/share/fonts/truetype/* "$TARGET_DIR/" 2>/dev/null || true

        find -L ${pkgs.noto-fonts-cjk-sans}/share/fonts/ -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp -f {} "$TARGET_DIR/" \; 2>/dev/null || true
        find -L ${pkgs.noto-fonts-cjk-serif}/share/fonts/ -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp -f {} "$TARGET_DIR/" \; 2>/dev/null || true
      '';
    };
  };

  programs = {
    helix = {
      enable = true;
      settings = {
        editor = {
          soft-wrap.enable = true;
          line-number = "relative";
        };
      };
    };
    starship = {
      enable = true;
      settings = {
        directory = {
          truncation_length = 3;
          truncate_to_repo = true;
        };
        add_newline = false;
        aws.disabled = true;
        gcloud.disabled = true;
        line_break.disabled = true;
      };
    };
    zoxide = {
      enable = true;
      enableBashIntegration = true;
    };
    fzf = {
      enable = true;
      enableBashIntegration = true;
      defaultCommand = "fd --type f --strip-cwd-prefix --hidden --exclude .git";
    };
    yazi = {
      enable = true;
      enableBashIntegration = true;
      shellWrapperName = "y";
      settings = {
        manager = {
          show_hidden = true;
          sort_by = "mtime";
          sort_reverse = true;
        };
      };
    };
    btop = {
      enable = true;
      settings = {
        vim_keys = true;
        update_ms = 2000;
        rounded_corners = true;
        proc_gradient = true;
        show_cpu_freq = true;
        show_coretemp = true;
      };
    };
    onlyoffice = {
      enable = true;
      settings = {
        UITheme = "theme-system";
        editorWindowMode = false;
        ignoreMsgAboutOpenTabs = true;
        titlebar = "custom";
      };
    };
  };

  gtk = {
    enable = true;

    gtk3.extraConfig = {
      gtk-enable-animations = false;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
    };

    gtk4.extraConfig = {
      gtk-enable-animations = false;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
    };
  };

  services = {
    gnome-keyring.enable = true;
  };

  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = true;
      desktop = null;
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
      publicShare = null;
      templates = null;
    };
  };
}
