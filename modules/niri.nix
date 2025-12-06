{ config, pkgs, lib, ... }:
{
  programs.niri = {
    enable = true;
  };

  xdg.configFile."niri/config.kdl".source = ../assets/niri.kdl;
}
