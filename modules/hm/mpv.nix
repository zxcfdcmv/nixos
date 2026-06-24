{ config, pkgs, ... }:
{
  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      uosc
      thumbfast
    ];
    config = {
      osc = "no";
      border = "no";
      script-opts = "thumbfast-network=yes,thumbfast-grab=yes";
    };
  };
}
