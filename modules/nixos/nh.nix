{ pkgs, userSettings, ... }:
{
  programs.nh = {
    enable = true;
    flake = "${userSettings.dotfilesDir}";
    clean = {
      enable = true;
      dates = "daily";
      extraArgs = "--keep-since 4d --keep 3";
    };
  };
}
