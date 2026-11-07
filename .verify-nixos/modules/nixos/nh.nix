{ pkgs, userSettings, ... }:
{
  programs.nh = {
    enable = true;
    flake = "${userSettings.dotfilesDir}";
    clean = {
      enable = true;
      dates = "daily";
      extraArgs = "--keep 3";
    };
  };
}
