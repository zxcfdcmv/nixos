{ config, lib, pkgs, userSettings, ... }:

let
  casual_preloader = pkgs.runCommand "casual_preloader" {
    nativeBuildInputs = [ pkgs.unzip ];
    src = pkgs.fetchurl {
      url = "https://filecache20.gamebanana.com/wips/casual_preloader_102624.zip";
      sha256 = "sha256-W4W9IyJ8v16MEkLOoHdIRsHejjD8Z54j5+fqPgBMpxY=";
    };
  } ''
    mkdir -p $out
    unzip -q "$src" -d $out/
    mv $out/_modern\ casual\ preloader/* $out/
    rmdir $out/_modern\ casual\ preloader
  '';

  flattf2rgl = pkgs.fetchurl {
    url = "${userSettings.githubProxy}/https://github.com/palmtopangie/FlatTF2RGL/releases/download/v3/flattf2rgl.vpk";
    sha256 = "sha256-hLSYA1dypUpZmDTU+6mGYvU2CeISxftrLS1DDO2ZN+M=";
  };

  lowvisFlamethrower = pkgs.runCommand "lowvis-flamethrower" {
    buildInputs = [ pkgs.unrar ];
    src = pkgs.fetchurl {
      url = "https://filecache20.gamebanana.com/mods/lowvis_64x_transparentflamethrower_d93da.rar";
      sha256 = "sha256-heW4Lzb3CfOGJF/fCIl60nAcYfPtzWDIzIvLWb74R5E=";
    };
  } ''
    mkdir -p $out
    unrar x "$src" "$out/"
  '';

  oldschoolPack = pkgs.fetchzip {
    url = "https://filecache20.gamebanana.com/mods/oldschool_fortress_2-3-0.zip";
    sha256 = "sha256-mJd4vyKwpSdQmQCYFM2yLfGTccePfSUyFISgy4w1Dh4=";
    stripRoot = false;
  };

  lighthud = pkgs.fetchzip {
    url = "${userSettings.githubProxy}/https://github.com/Hypnootize/lighthud/archive/refs/heads/main.zip";
    sha256 = "sha256-JN0qlnroV6HgHyxzKCXXnWan3+JK78qqYfFSCEh25lA=";
    stripRoot = true;
  };

  centered_viewmodels_vpk = pkgs.runCommand "centered-viewmodels-vpk" {
    nativeBuildInputs = [ pkgs.unrar ];
    src = pkgs.fetchurl {
      url = "https://filecache20.gamebanana.com/mods/centered_viewmodels.rar";
      sha256 = "sha256-UwUXOmsRMf67CpyzNBO74PtJI4kGr8y7VkjbtB/Ok+E=";
    };
  } ''
    mkdir -p $out
    unrar x "$src" "$out/"
  '';

  # bfg9000
  # tf2-bfg-mangler-centered-casual = pkgs.runCommand "tf2-bfg-mangler-centered-casual" {
  #   nativeBuildInputs = [ pkgs.unzip ];
  #   src = pkgs.fetchurl {
  #     url = "https://filecache45.gamebanana.com/mods/tf2-bfg-mangler-centered-casual_fd237.zip";
  #     sha256 = lib.fakeSha256;
  #   };
  # } ''
  #   mkdir -p $out
  #   unzip -q "$src" -d $out/

  #   rm "$out/bfg_9000_cow_mangler_centered_(casual)_(with_sounds).vpk"
  # '';

  # rayshudVersion = "2026.0111";
  # rayshud = pkgs.fetchzip {
  #   url = "${userSettings.githubProxy}/https://github.com/raysfire/rayshud/releases/download/${rayshudVersion}/rayshud.zip";
  #   sha256 = "sha256-3U1/4TZmd0DgrVXcQ1lvX5zko+SYrb+sj5XrKHG9+hk=";
  #   stripRoot = true;
  # };


  tf2Assets = ../../assets/tf2/tf;
  
  # 递归读取目录（同上）
  recursiveFiles = dir:
    let
      contents = builtins.readDir dir;
      mkEntry = name: type:
        if type == "directory" then
          recursiveFiles (dir + "/${name}")
        else if type == "regular" then
          [ (dir + "/${name}") ]
        else
          [ ];
    in
      lib.concatLists (lib.mapAttrsToList mkEntry contents);
  
  tf2Files = recursiveFiles tf2Assets;
  
  tf2AssetsStr = toString tf2Assets;
  tf2AssetsLen = builtins.stringLength tf2AssetsStr;
  
  toRelative = path: 
    let
      pathStr = toString path;
      pathLen = builtins.stringLength pathStr;
    in
      lib.substring (tf2AssetsLen + 1) (pathLen - tf2AssetsLen - 1) pathStr;
  
  mkFileEntry = file: {
    name = ".local/share/Steam/steamapps/common/Team Fortress 2/tf/${toRelative file}";
    value = { source = file; };
  };
  
  tf2FileEntries = lib.listToAttrs (map mkFileEntry tf2Files);
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
              "-vulkan"
              "-language" "schinese"
              "+cc_lang" "schinese"
              "-lv"
              "-novid"
              "-nojoy"
              "-useallavailablecores"
              # "-noaafonts"
              "-high"
              "-console"
              "-noipx"
              "-nohltv"
            ];
          };
        };
        team-fortress-2 = {
          id = 440;
          launchOptions = {
            wrappers = [
              (lib.getExe' pkgs.gamemode "gamemoderun")
            ];
            env = {
              "__GL_SHADER_DISK_CACHE" = "1";
              "__GL_SHADER_DISK_CACHE_SKIP_CLEANUP" = "1";
              "__GL_THREADED_OPTIMIZATIONS" = "1";
            };
            args = [
              "-vulkan"
              "-novid"
              "-nojoy"
              "-nosteamcontroller"
              "-nohltv"
              "-noipx"
              "-console"
              "-particles" "1"
              "-nocustomtools"
              "-softparticlesdefaultoff"
              "-noprewarm"
              "+exec" "preloader.cfg"
            ];
          };
        };
      };
    };

    home.file = {
      # l4d2
      ".local/share/Steam/steamapps/common/Left 4 Dead 2/left4dead2/cfg/autoexec.cfg".source = ../../assets/l4d2/autoexec.cfg;
      ".local/share/Steam/steamapps/common/Left 4 Dead 2/left4dead2/ems/lxc/inspect_weapon/settings.txt".source = ../../assets/l4d2/inspect_settings.txt;

      # tf2
      # ".local/share/Steam/steamapps/common/Team Fortress 2/tf/custom/rayshud".source = rayshud;
      ".local/share/Steam/steamapps/common/Team Fortress 2/tf/custom/modern_casual_preloader" = {
        source = "${casual_preloader}";
        recursive = true;
      };
      ".local/share/Steam/steamapps/common/Team Fortress 2/tf/custom/centered viewmodels.vpk" = {
        source = "${centered_viewmodels_vpk}/centered viewmodels.vpk";
      };
      # ".local/share/Steam/steamapps/common/Team Fortress 2/tf/custom/tf2-bfg-mangler-centered-casual" = {
      #   source = "${tf2-bfg-mangler-centered-casual}";
      #   recursive = true;
      # };
      ".local/share/Steam/steamapps/common/Team Fortress 2/tf/custom/lighthud".source = lighthud;
      ".local/share/Steam/steamapps/common/Team Fortress 2/tf/custom/flattf2rgl.vpk".source = flattf2rgl;
      ".local/share/Steam/steamapps/common/Team Fortress 2/tf/custom/[Lowvis] 64x TransparentFlamethrower.vpk".source = "${lowvisFlamethrower}/[Lowvis] 64x TransparentFlamethrower.vpk";
      # oldschool
      ".local/share/Steam/steamapps/common/Team Fortress 2/tf/custom/oldschool_fortress_2.3.0_hr.vpk" = {
        source = "${oldschoolPack}/oldschool_fortress_2.3.0_hr.vpk";
      };
      ".local/share/Steam/steamapps/common/Team Fortress 2/tf/custom/oldschool_fortress_particles.vpk" = {
        source = "${oldschoolPack}/oldschool_fortress_particles.vpk";
      };
    } // tf2FileEntries;
  };
}
