{ config, pkgs, ... }:
{
  home = {
    username = "zxcfdcmv";
    homeDirectory = "/home/zxcfdcmv";
    packages = with pkgs; [
      microsoft-edge
      fuzzel
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

  xresources.properties = {
    "Xcursor.size" = 12;
  };

  programs = {
    bash = {
      enable = true;
      enableCompletion = true;
      bashrcExtra = ''
        export PATH="$PATH:$HOME/bin:$HOME/.local/bin"
      '';
      shellAliases = {
        delete = "sudo nix-collect-garbage -d";
        hx = "sudo -E hx";
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
    alacritty = {
      enable = true;
      settings = {
        env.TERM = "xterm-256color";
        font = {
          size = 14;
        };
        colors.draw_bold_text_with_bright_colors = true;
        scrolling.multiplier = 5;
        selection.save_to_clipboard = true;
      };
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
  };

  xdg = {
    configFile = {
      # "niri/config.kdl".source = ./niri/config.kdl;
      "niri/config.kdl".text = ''
        ${builtins.readFile ./niri/config.kdl}
        spawn-sh-at-startup "export GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx XMODIFIERS=@im=fcitx SDL_IM_MODULE=fcitx GLFW_IM_MODULE=fcitx GLYPH_IM_MODULE=fcitx && fcitx5 -d"
      '';
    };
  };
  home.stateVersion = "25.11";
}
