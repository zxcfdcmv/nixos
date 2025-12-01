{ config, pkgs, lib, ... }:
{
  home = {
    stateVersion = "26.05";
    username = "zxcfdcmv";
    homeDirectory = "/home/zxcfdcmv";
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
    };
    packages = with pkgs; [
      p7zip
      ripgrep
      bat
      eza
      fd
      dust
      procs
      bottom
      poppler
      imagemagick
      ffmpegthumbnailer
      gamescope
      microsoft-edge
      teamspeak6-client
      pkgs.bibata-cursors
      (prismlauncher.override {
        jdks = [ zulu21 ];
      })
    ];
  };

  i18n = {
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          fcitx5-gtk
          qt6Packages.fcitx5-chinese-addons
          qt6Packages.fcitx5-configtool
        ];
      };
    };
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
        grep = "rg --hidden --smart-case";
        rg   = "rg --hidden --smart-case";
        find = "fd";
        cat  = "bat -pp";
        ls   = "eza --group-directories-first --git";
        ll   = "eza --group-directories-first --git --long --icons";
        l   = "eza --group-directories-first --git --long --icons";
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
    foot = {
      enable = true;
      server.enable = true;
    };
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

  xdg = {
    configFile = {
      "niri/config.kdl".source = ./niri/config.kdl;
      "foot/foot.ini".source = ./foot/foot.ini;
    };
  };
}
