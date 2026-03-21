{ config, pkgs, ... }:

{
  home.file.".config/niri/config.kdl".text = ''
    ${builtins.readFile ../../assets/niri.kdl}

    spawn-at-startup "swaybg" "-i" "${config.stylix.image}" "-m" "fill"
  '';
  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland";
  };
}
