{ config, pkgs, lib, userSettings, ... }:

let
  # 所有松散文件 Mod 列表
  nativeMods = [
    ada_swap_02
  ];

  # 松散文件 Mods
  ada_swap_02 = pkgs.fetchzip {
    url = "${userSettings.githubProxy}/https://github.com/zxcfdcmv/nixos/releases/download/re4/ada_swap_02.zip";
    sha256 = "sha256-fc+8+HmfUVwxbE6bsGwvu+DYzpyEk+0iAxnE/fvaakk=";
    stripRoot = false;
  };

  reframework_mod = pkgs.fetchzip {
    url = "https://github.com/zxcfdcmv/nixos/releases/download/re4/reframework_mod.zip";
    sha256 = "sha256-pQu+fErz/BcyPdkYIPzs9pS02YUBKZflqMV+OLzMU00=";
    stripRoot = false;
  };

  # ========== REFramework ============
  reframework = pkgs.runCommand "reframework-re4" {
    nativeBuildInputs = [ pkgs.unzip ];
    src = pkgs.fetchurl {
      url = "${userSettings.githubProxy}/https://github.com/zxcfdcmv/nixos/releases/download/re4/REFramework-12-Nightly01215-1770463547.zip";
      sha256 = "sha256-H7WpEIzN7gdWn4W31V/upK4ZKXhs/45+GvpCdIcG77I=";
    };
  } ''
    mkdir -p $out
    unzip -q "$src" -d $out/
  '';

  stack_size_all_9999 = pkgs.runCommand "stack_size_all_9999" {
    nativeBuildInputs = [ pkgs.unzip ];
    src = pkgs.fetchurl {
      url = "${userSettings.githubProxy}/https://github.com/zxcfdcmv/nixos/releases/download/re4/stack_size_all_9999.zip";
      sha256 = "sha256-Gl3YiDQZlLpzR0/xMzRM2EcHS5Z1y9l4yOFSi4A40kM=";
    };
  } ''
    mkdir -p $out
    unzip -q "$src" -d $out/
  '';

  ada_swap_01 = pkgs.fetchzip {
    url = "https://github.com/zxcfdcmv/nixos/releases/download/re4/ada_swap_01.zip";
    sha256 = "sha256-zLQHr2GcQUHxNy23R3eG/v1+Ea/rfI8+WrJxu1k1PFw=";
    stripRoot = false;
  };

  classic_re4_laser = pkgs.fetchzip {
    url = "https://github.com/zxcfdcmv/nixos/releases/download/re4/classic_re4_laser.zip";
    sha256 = "sha256-dd52DNKw8f2gtnQK5nNOPrZjt5x7KKnzmgtr6TdhLyg=";
    stripRoot = false;
  };

  rifles_ada_jiggle = pkgs.fetchzip {
    url = "https://github.com/zxcfdcmv/nixos/releases/download/re4/3rd_rifles_ada_jiggle.zip";
    sha256 = "sha256-qCLefrfHqz0EE982eGbt57aplbm2ZZokIyhMmD03db4=";
    stripRoot = false;
  };

  realistic_fire = pkgs.fetchzip {
    url = "https://github.com/zxcfdcmv/nixos/releases/download/re4/realistic_fire.zip";
    sha256 = "sha256-LEyCncaGdw4isSXa2+e8UM77SSQuR/WFMBVtYgtYkGc=";
    stripRoot = false;
  };

  gameDir = ".local/share/Steam/steamapps/common/RESIDENT EVIL 4  BIOHAZARD RE4";
in
{
  programs.steam.config.apps.resident-evil-4-remake = {
    id = 2050650;
    launchOptions = {
      args = [
        "WINEDLLOVERRIDES=\"dinput8.dll=n,b\""
      ];
    };
  };
  home.file = {
    "${gameDir}/dinput8.dll".source = "${reframework}/dinput8.dll";
    
    # "${gameDir}/reframework/autorun/manual_flashlight.lua".source = "${manual-flashlight}/manual_flashlight.lua";

    "${gameDir}/re_chunk_000.pak.patch_007.pak".source = "${stack_size_all_9999}/re_chunk_000.pak.patch_007.pak";

    "${gameDir}/re_chunk_000.pak.patch_008.pak".source = "${ada_swap_01}/re_chunk_000.pak.patch_008.pak";
    "${gameDir}/re_chunk_000.pak.patch_009.pak".source = "${ada_swap_01}/re_chunk_000.pak.patch_009.pak";
    "${gameDir}/re_chunk_000.pak.patch_010.pak".source = "${ada_swap_01}/re_chunk_000.pak.patch_010.pak";
    "${gameDir}/re_chunk_000.pak.patch_011.pak".source = "${ada_swap_01}/re_chunk_000.pak.patch_011.pak";
    "${gameDir}/re_chunk_000.pak.patch_012.pak".source = "${ada_swap_01}/re_chunk_000.pak.patch_012.pak";

    "${gameDir}/re_chunk_000.pak.patch_013.pak".source = "${classic_re4_laser}/re_chunk_000.pak.patch_013.pak";
    "${gameDir}/re_chunk_000.pak.patch_014.pak".source = "${classic_re4_laser}/re_chunk_000.pak.patch_014.pak";

    "${gameDir}/re_chunk_000.pak.patch_015.pak".source = "${rifles_ada_jiggle}/re_chunk_000.pak.patch_015.pak";
    "${gameDir}/re_chunk_000.pak.patch_016.pak".source = "${rifles_ada_jiggle}/re_chunk_000.pak.patch_016.pak";

    "${gameDir}/re_chunk_000.pak.patch_017.pak".source = "${realistic_fire}/re_chunk_000.pak.patch_017.pak";

    "${gameDir}/reframework" = {
      source = "${reframework_mod}/reframework";
      recursive = true;
    };
  };

  home.activation.re4-natives = lib.hm.dag.entryAfter ["writeBoundary"] ''
    NATIVES_DIR="${config.home.homeDirectory}/${gameDir}/natives"
  
    # 先给写权限再删除
    [ -d "$NATIVES_DIR" ] && chmod -R +w "$NATIVES_DIR"
    rm -rf "$NATIVES_DIR"
    mkdir -p "$NATIVES_DIR/stm"
  
    ${lib.concatMapStringsSep "\n" (mod: ''
      if [ -d "${mod}/natives/stm" ]; then
        cp -r "${mod}/natives/stm/"* "$NATIVES_DIR/stm/" 2>/dev/null || true
      fi
    '') nativeMods}
  
    # 给新复制的文件加写权限
    chmod -R +w "$NATIVES_DIR"
  '';
}
