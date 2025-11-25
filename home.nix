{ config, pkgs, lib, ... }:
{
  home = {
    stateVersion = "25.11";
    username = "zxcfdcmv";
    homeDirectory = "/home/zxcfdcmv";
    packages = with pkgs; [
      microsoft-edge
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
          fcitx5-rime
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
        # hx = "sudo -E hx";
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
  };

  xdg = {
    configFile = {
      "niri/config.kdl".source = ./niri/config.kdl;
      "foot/foot.ini".source = ./foot/foot.ini;
    };
    dataFile = {
      "fcitx5/rime" = {
        source = pkgs.fetchFromGitHub {  
          owner = "iDvel";  
          repo = "rime-ice";  
          # 如果有问题请将 sha256 替换为 lib.fakeSha256，运行重建命令获取最新的 hash 值。  
          rev = "main";   
          sha256 = "sha256-Ei8qeo5Misu0J/yZ894c0EbUFz/8EmqWqiEy8O9TD30=";   
        };       
        recursive = true;
      };
      "fcitx5/rime/default.custom.yaml".text = ''
         patch:  
          "menu/page_size": 5  # 候选词数量  
          schema_list:  
            - schema: rime_ice_double_pinyin_flypy   # 雾凇拼音（全拼）  
      '';         
    };
  };
}
