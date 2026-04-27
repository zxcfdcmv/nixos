{ config, lib, pkgs, userSettings, ... }:
{
  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };
    gamescope = {
      enable = true;
      capSysNice = false;
    };
  };

  home-manager.users.${userSettings.username} = { config, steam-config-nix, ...}: {
    imports = [ steam-config-nix.homeModules.default ];

    programs.steam.config = {
      enable = true;
      closeSteam = true;
      defaultCompatTool = "GE-Proton";
      apps = {
        deep-rock-galactic = {
          id = 548430;
          launchOptions = {
            args = [
              "-disablemodding"  # 禁用 MOD 支持，提高兼容性和性能
            ];
          };
        };
      };
    };
  };
}
