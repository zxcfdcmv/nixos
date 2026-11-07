{ config, pkgs, ... }:
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "${pkgs.foot}/bin/footclient";
        layer = "overlay";
        lines = 0;
        width = "30";

        icons-enabled = false;
        hide-before-typing = true;
      };
    };
  };

  xdg.configFile."fuzzel/fuzzel.ini".force = true;
}
