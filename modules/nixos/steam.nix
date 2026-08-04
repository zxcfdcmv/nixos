{ config, lib, pkgs, userSettings, ... }:

let
  witchfire = pkgs.fetchzip {
    url = "https://github.com/zxcfdcmv/nixos/releases/download/re4/witchfire.zip";
    sha256 = "sha256-PFzk9O5AZyGfLLIY8wpiXJ0iqLwz0KWndHt61FM+y6s=";
    stripRoot = false;
  };
in
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
    gamemode.enable = true;
  };

  home-manager.users.${userSettings.username} = { config, steam-config-nix, ...}: {
    imports = [
      steam-config-nix.homeModules.default
      ../games/tf2.nix
      ../games/re4.nix
    ];

    programs.steam.config = {
      enable = true;
      onSteamRunning = "close";
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
            wrappers = [
              (lib.getExe' pkgs.gamemode "gamemoderun")
            ];
            env = {
              "STEAM_COMPAT_RUNTIME_SDL2" = "1";
              "__GL_SHADER_DISK_CACHE" = "1";
              "__GL_SHADER_DISK_CACHE_SKIP_CLEANUP" = "1";
              "__GL_THREADED_OPTIMIZATIONS" = "1";
            };
            args = [
              "-windowed"
              "-w" "800"
              "-h" "600"
              "-noborder"
              "-vulkan"
              "-language" "schinese"
              "+cc_lang" "schinese"
              "-lv"
              "-novid"
              "-nojoy"
              "-useallavailablecores"
              "-noaafonts"
              "-high"
              "-console"
              "-noipx"
              "-nohltv"
            ];
          };
        };
      };
    };

    home.file = {
      # l4d2
      ".local/share/Steam/steamapps/common/Left 4 Dead 2/left4dead2/cfg/autoexec.cfg".source = ../../assets/l4d2/autoexec.cfg;
      ".local/share/Steam/steamapps/common/Left 4 Dead 2/left4dead2/ems/lxc/inspect_weapon/settings.txt".source = ../../assets/l4d2/inspect_settings.txt;

      ".local/share/Steam/steamapps/common/Witchfire/Witchfire/Content/Paks/" = {
        source = "${witchfire}";
        recursive = true;
      };
    };
  };
}
