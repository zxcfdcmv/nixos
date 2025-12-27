{ config, pkgs, lib, ... }:
{
  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland";
  };
  xdg.configFile."niri/config.kdl" = {
    source = ../../assets/niri.kdl;
    force = true;
  };
}
