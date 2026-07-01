{ config, pkgs, lib, ... }:

let
  st-snazzy-custom = pkgs.st-snazzy.overrideAttrs (oldAttrs: {
    postPatch = (oldAttrs.postPatch or "") + ''
      # 改字体
      sed -i 's|static char \*font = ".*"|static char *font = "Maple Mono NF CN:size=14:antialias=true:autohint=true"|' config.def.h
      
      # 改透明
      sed -i 's|float alpha = 1.0;|float alpha = 0.8;|' config.def.h
      
      # 改内边距
      sed -i 's|static int borderpx = .*|static int borderpx = 5;|' config.def.h
    '';
  });
in
{
  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        # dpi-aware = "yes";
        term = "xterm-256color";
        # font = "Maple Mono NF CN:size=12";

        # font = "${config.stylix.fonts.serif.name}:size=${toString config.stylix.fonts.sizes.terminal}";

        pad = "5x5 center";
        selection-target = "both";
      };
      mouse = { hide-when-typing = "yes";
      };
      scrollback = {
        indicator-position = "none";
        lines = "10000";
        multiplier = "3.0";
      };
      # "colors-dark" = {
      #   # alpha = "0.80";
      #   alpha = config.stylix.opacity.terminal;
      # };
    };
  };
  # xdg.configFile."foot/foot.ini".force = true;
  
  home.packages = with pkgs; [ st-snazzy-custom ];
}
