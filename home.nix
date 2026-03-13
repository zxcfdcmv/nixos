{ config, pkgs, lib, userSettings, ... }:
{
  imports = [
    ./modules/hm/niri.nix
    ./modules/hm/noctalia.nix
    ./modules/hm/swayidle.nix
    ./modules/hm/bash.nix
    ./modules/hm/scripts.nix
    ./modules/hm/foot.nix
    ./modules/hm/fuzzel.nix
    ./modules/hm/input.nix              # 框架
    ./modules/hm/input-xiaohe.nix       # 输入方案
    ./modules/hm/zed-editor.nix
    ./modules/hm/proxy.nix
    ./modules/hm/input-remapper.nix     # 按键映射
    ./modules/hm/games.nix
  ];

  home = {
    stateVersion = "25.11";
    username = userSettings.username;
    homeDirectory = "/home/${userSettings.username}";

    # 指针主题
    pointerCursor = {
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
      ripgrep bat eza fd dust
      p7zip poppler imagemagick ffmpegthumbnailer
      xwayland-satellite
      wl-clipboard
      nh nvd nix-output-monitor

      # 应用
      microsoft-edge
      (prismlauncher.override {
        jdks = [ zulu21 zulu25 ];
      })
      teamspeak6-client
      localsend
      heroic
    ];
  };

  programs = {
    helix = {
      enable = true;
      settings = {
        theme = "base16_transparent";
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
        color_theme = "TTY";
        vim_keys = true;
        update_ms = 2000;
        rounded_corners = true;
        proc_gradient = true;
        show_cpu_freq = true;
        show_coretemp = true;
      };
    };
  };
}
