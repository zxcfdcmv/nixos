{ config, pkgs, lib, ... }:
{

  xdg.configFile."niri/config.kdl" = {
    source = ../../assets/niri.kdl;
    force = true;
  };
  
}
