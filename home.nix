{ config, pkgs, lib, userSettings, ... }:
{
  imports = [
    ./modules/hm/bash.nix
    ./modules/hm/scripts.nix
    ./modules/hm/terminal.nix
    ./modules/hm/fuzzel.nix
    ./modules/hm/input.nix              # 框架
    ./modules/hm/input-xiaohe.nix       # 输入方案
    ./modules/hm/zed-editor.nix
    ./modules/hm/proxy.nix
    ./modules/games/cdda.nix
    # ./modules/hm/qutebrowser.nix
    ./modules/hm/email.nix
    ./modules/hm/mint_notag.nix
    ./modules/hm/fireaxe.nix
    ./modules/hm/mpv.nix
    ./modules/hm/crosshair.nix
  ];

  home = {
    stateVersion = "25.11";
    username = userSettings.username;
    homeDirectory = "/home/${userSettings.username}";

    # 指针主题
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
      # nh需要
      NH_FLAKE = "${userSettings.dotfilesDir}";
    };
    
    packages = with pkgs; [
      # 基础
      ## 命令行工具
      ripgrep bat eza fd dust
      p7zip unzip unrar poppler imagemagick ffmpegthumbnailer
      xwayland-satellite
      wl-clipboard-rs
      nvd nix-output-monitor
      openssl
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

      ## 对比工具
      diffoscope icdiff

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
      localsend
      heroic
      ayugram-desktop
      piliplus
      ## 键盘映射
      kanata
      # wemeet
      # bilibili-tui
      ## office
      wpsoffice-cn
      anki

      ## 截图
      ksnip
      ## 剪切板
      copyq
    ];
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
}
