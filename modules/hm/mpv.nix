{ config, pkgs, ... }:
{
  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      uosc
      thumbfast
      bdanmaku
      sponsorblock
      quality-menu
      reload
    ];
    config = {
      osc = "no";
      border = "no";
      "osd-bar" = "no";
      script-opts = "thumbfast-network=yes,thumbfast-grab=yes";
    };
  };
}
