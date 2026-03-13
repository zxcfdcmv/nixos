{ pkgs, ... }:

let
  cdda-version = "2026-03-13-0525";
  cdda-url = "https://gh-proxy.com/https://github.com/CleverRaven/Cataclysm-DDA/releases/download/cdda-experimental-${cdda-version}/cdda-linux-with-graphics-and-sounds-x64-${cdda-version}.tar.gz";
  cdda-hash = "sha256-emhCmsXBNH7q61SBgxjny4L3CpT3MXBsRU9ZuHzofKY=";

  cdda-bin = pkgs.stdenv.mkDerivation {
    pname = "cataclysm-dda-experimental";
    version = cdda-version;
    
    src = pkgs.fetchurl {
      url = cdda-url;
      hash = cdda-hash;
    };
    
    dontConfigure = true;
    dontBuild = true;
    
    # installPhase = ''
    #   mkdir -p $out/bin $out/share/cataclysm-dda
    #   cp -r . $out/share/cataclysm-dda/
      
    #   # 创建启动脚本，添加 --userdir 参数
    #   cat > $out/bin/cataclysm-tiles << EOF
    #   #!/bin/sh
    #   # 切换到游戏数据目录
    #   cd $out/share/cataclysm-dda
    #   # 使用 --userdir 指定配置目录为 ~/.cataclysm-dda
    #   exec ./cataclysm-tiles --userdir "\$HOME/.cataclysm-dda" "\$@"
    #   EOF
    #   chmod +x $out/bin/cataclysm-tiles
    # '';

    installPhase = ''
      mkdir -p $out/bin $out/share/cataclysm-dda
      cp -r . $out/share/cataclysm-dda/
      
      # 创建启动脚本，使用 --userdir 参数指向 XDG 数据目录
      cat > $out/bin/cataclysm-tiles << EOF
      #!/bin/sh
      # 切换到游戏数据目录
      cd $out/share/cataclysm-dda
      # 使用 --userdir 指定配置目录为 XDG 数据目录
      exec ./cataclysm-tiles --userdir "\''${XDG_DATA_HOME:-\$HOME/.local/share}/cataclysm-dda" "\$@"
      EOF
      chmod +x $out/bin/cataclysm-tiles
    '';
  };

  cc-sounds = pkgs.fetchzip {
    url = "https://gh-proxy.com/github.com/Fris0uman/CDDA-Soundpacks/releases/download/2025-11-15/CC-Sounds.zip";
    hash = "sha256-qzD4T/Xg4y6+cix7W1by86xMC/1Oy2I7NECylDVFBHo=";
    stripRoot = false;
  };

in
{
  home.packages = [ cdda-bin ];
  # home.file.".cataclysm-dda/sound".source = cc-sounds;
  xdg.dataFile."cataclysm-dda/sound".source = cc-sounds;
}
