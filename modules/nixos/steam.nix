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
              "-disablemodding"
            ];
          };
        };
        project-zomboid = {
          id = 108600;
          launchOptions = {
            args = [
              "-Xms6G"
              "-Xmx6G"
            ];
          };
        };
        left-4-dead-2 = {
          id = 550;
          launchOptions = {
            env = {
              "STEAM_COMPAT_RUNTIME_SDL2" = "1";
              "__GL_SHADER_DISK_CACHE" = "1";
              "__GL_SHADER_DISK_CACHE_SKIP_CLEANUP" = "1";
            };
            args = [
              "-vulkan"
              "-language" "schinese"
              "+cc_lang" "schinese"
              "-lv"
              "-novid"
              "-nojoy"
              "-useallavailablecores"
              # "-noaafonts"
              "-high"
              "-noipx"
              "-nohltv"
              # "-heapsize" "1572864"
            ];
          };
        };
      };
    };

    home.file = {
      ".local/share/Steam/steamapps/common/Left 4 Dead 2/left4dead2/cfg/autoexec.cfg".source = ../../assets/l4d2/autoexec.cfg;
      ".local/share/Steam/steamapps/common/Left 4 Dead 2/left4dead2/ems/lxc/inspect_weapon/settings.txt".source = ../../assets/l4d2/inspect_settings.txt;
    };
  };
}
