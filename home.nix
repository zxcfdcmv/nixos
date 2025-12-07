{ config, pkgs, lib, ... }:
{
  imports = [
    ./modules/foot.nix
    ./modules/noctalia.nix
    ./modules/input-method.nix    # 框架
    ./inputs/xiaohe.nix           # 输入方案
  ];

  home = {
    stateVersion = "26.05";
    username = "zxcfdcmv";
    homeDirectory = "/home/zxcfdcmv";

    # 指针主题
    pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      name = "Bibata-Modern-Ice";
      size = 32;
      package = pkgs.bibata-cursors;
    };
    sessionVariables = {
      XCURSOR_SIZE = "24";
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XDG_CURRENT_DESKTOP = "niri";
      QT_QPA_PLATFORM = "wayland";
    };
    
    # 用户包
    packages = with pkgs; [
      # 基础
      ripgrep bat eza fd dust procs bottom
      p7zip poppler imagemagick ffmpegthumbnailer
      wl-clipboard xwayland-satellite

      # 浏览器 / 游戏
      microsoft-edge
      (prismlauncher.override {
        jdks = [ zulu21 ];
      })
      teamspeak6-client
      # pkgs.bibata-cursors
    ];
  };

  programs = {
    bash = {
      enable = true;
      enableCompletion = true;
      bashrcExtra = ''
        export PATH="$PATH:$HOME/bin:$HOME/.local/bin"
      '';
      initExtra = ''
        eval "$(zoxide init bash)"
        eval "$(fzf --bash)" 2>/dev/null || true
      '';
      shellAliases = {
        rg   = "rg --hidden --smart-case";
        cat  = "bat -pp";
        ls   = "eza --group-directories-first --git";
        ll   = "eza --group-directories-first --git --long --icons";
        l    = "eza --group-directories-first --git --long --icons";
        du   = "dust";
        ps   = "procs";
        top  = "btm";
        z    = "zoxide query --interactive";
        delete = "sudo nix-collect-garbage -d";
        build  = "sudo nixos-rebuild build --flake ~/nixos#nixos";
        switch = "sudo nixos-rebuild switch --flake ~/nixos#nixos";
      };
    };
    helix = {
      enable = true;
      settings = {
        theme = "bogster";
        editor = {
          soft-wrap = {
            enable = true;
          };
        };
      };
    };
    # alacritty = {
    #   enable = true;
    #   settings = {
    #     env.TERM = "xterm-256color";
    #     font = {
    #       size = 14;
    #     };
    #     colors.draw_bold_text_with_bright_colors = true;
    #     scrolling.multiplier = 5;
    #     selection.save_to_clipboard = true;
    #   };
    # };
    fuzzel = {
      enable = true;
    };
    starship = {
      enable = true;
      settings = {
        add_newline = false;
        aws.disabled = true;
        gcloud.disabled = true;
        line_break.disabled = true;
      };
    };
    zoxide.enable = true;
    fzf.enable = true;
    yazi.enable = true;
  };

  xdg.configFile."niri/config.kdl".source = ./assets/niri.kdl;
}
