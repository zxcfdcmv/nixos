{ config, pkgs, lib, ... }:
{
  imports = [
    ./modules/hm/niri.nix
    ./modules/hm/noctalia.nix
    ./modules/hm/bash.nix
    ./modules/hm/scripts.nix
    ./modules/hm/foot.nix
    ./modules/hm/input.nix              # 框架
    ./modules/hm/input-xiaohe.nix       # 输入方案
    ./modules/hm/zed-editor.nix
    ./modules/hm/proxy.nix
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
    };
    
    packages = with pkgs; [
      # 基础
      ripgrep bat eza fd dust procs bottom
      p7zip poppler imagemagick ffmpegthumbnailer
      wl-clipboard xwayland-satellite

      # 应用
      microsoft-edge
      (prismlauncher.override {
        jdks = [ zulu17 zulu21 zulu25 ];
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
          soft-wrap = {
            enable = true;
          };
        };
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
    fuzzel.enable = true;
    zoxide.enable = true;
    fzf.enable = true;
    yazi.enable = true;
  };
}
