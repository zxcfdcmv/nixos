{ config, pkgs, lib, ... }:
{
  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        dpi-aware = "yes";
        term = "xterm-256color";
        font = "Maple Mono NF CN:size=12";
        pad = "5x5 center";
        selection-target = "both";
      };
      mouse = {
        hide-when-typing = "yes";
      };
      scrollback = {
        indicator-position = "none";
        lines = "10000";
        multiplier = "3.0";
      };
      "colors-dark" = {
        alpha = "0.80";
      };
    };
  };
  xdg.configFile."foot/foot.ini".force = true;
}
