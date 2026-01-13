{ config, pkgs, ... }:
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "${pkgs.foot}/bin/footclient";
        layer = "overlay";
        include = "~/.config/fuzzel/themes/noctalia";
      };
    };
  };
}
