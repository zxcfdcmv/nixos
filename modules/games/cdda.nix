{ pkgs, userSettings,  ... }:
let
  # cdda-version = "2026-03-28-0826";
  # cdda-hash = "sha256-HAGMKzpizxI9OTgFAQj4UIFGuvwBTgMYs3ljOd6T6F0=";
  cdda-version = "2026-03-28-2123";
  cdda-hash = "sha256-uwqKZ06PPt7w5m0v2x0t3+ynRlHafE2SUjDxY/PL8sE=";

  # cdda设置
  mySettings = {
    # 自动备注
    AUTO_NOTES = "true";
    AUTO_NOTES_STAIRS = "true";
    AUTO_NOTES_MAP_EXTRAS = "true";
    AUTO_NOTES_DROPPED_FAVORITES = "true";
    # 音效包
    SOUNDPACKS = "CC-Sounds";
    # 语言
    USE_LANG = "zh_CN";
    # 计量单位
    USE_CELSIUS = "celsius";
    USE_METRIC_SPEEDS = "t/t";
    USE_METRIC_WEIGHTS = "kg";
    VOLUME_UNITS = "l";
    DISTANCE_UNITS = "metric";
    "24_HOUR" = "12h";
    # 快捷操作
    USE_PINYIN_SEARCH = "true";
    # 字体设置
    FONT_BLENDING = "true";
    FONT_WIDTH = 12;
    FONT_HEIGHT = 24;
    FONT_SIZE = 24;
    # 贴图包
    TILESET = "UltimateCataclysm";
    OVERMAP_TILES = "UltimateCataclysm";

    # 侧边栏小地图设置
    PIXEL_MINIMAP_MODE = "squares";
    PIXEL_MINIMAP_SCALE_TO_FIT = "true";
  };  

  cdda-url = "${userSettings.githubProxy}/https://github.com/CleverRaven/Cataclysm-DDA/releases/download/cdda-experimental-${cdda-version}/cdda-linux-with-graphics-and-sounds-x64-${cdda-version}.tar.gz";

  cdda-bin = pkgs.stdenv.mkDerivation {
    pname = "cataclysm-dda-experimental";
    version = cdda-version;
    
    src = pkgs.fetchurl {
      url = cdda-url;
      hash = cdda-hash;
    };
    
    dontConfigure = true;
    dontBuild = true;
    
    installPhase = ''
      mkdir -p $out/bin $out/share/cataclysm-dda
      cp -r . $out/share/cataclysm-dda/
      
      cat > $out/bin/cdda << EOF
      #!/bin/sh
      # 切换到游戏数据目录
      cd $out/share/cataclysm-dda
      # 使用 --userdir 指定配置目录为 XDG 数据目录
      exec ./cataclysm-tiles --userdir "\''${XDG_DATA_HOME:-\$HOME/.local/share}/cataclysm-dda" "\$@"
      EOF
      chmod +x $out/bin/cdda
    '';
  };

  # 音效包
  cc-sounds = pkgs.fetchzip {
    url = "${userSettings.githubProxy}/github.com/Fris0uman/CDDA-Soundpacks/releases/download/2025-11-15/CC-Sounds.zip";
    hash = "sha256-qzD4T/Xg4y6+cix7W1by86xMC/1Oy2I7NECylDVFBHo=";
    stripRoot = false;
  };

  # 字体
  mapleMono = pkgs.maple-mono.NF-CN;
  fontsConfig = pkgs.writeText "cdda-fonts.json" ''
    {
      "typeface": [ 
        { "path": "${mapleMono}/share/fonts/truetype/MapleMono-NF-CN-Regular.ttf", "hinting": "Default" }
      ],
      "gui_typeface": [ 
        { "path": "${mapleMono}/share/fonts/truetype/MapleMono-NF-CN-Regular.ttf", "hinting": "Default" }
      ],
      "map_typeface": [ 
        { "path": "${mapleMono}/share/fonts/truetype/MapleMono-NF-CN-Regular.ttf", "hinting": "Default" }
      ],
      "overmap_typeface": [ 
        { "path": "${mapleMono}/share/fonts/truetype/MapleMono-NF-CN-Regular.ttf", "hinting": "Default" }
      ]
    }
  '';

  # 设置
  mkOptions = attrs: 
    builtins.map (name: { 
      inherit name; 
      value = builtins.toString attrs.${name};
    }) (builtins.attrNames attrs);
  optionsJSON = pkgs.writeText "cdda-options.json" (builtins.toJSON (mkOptions mySettings));
in
{
  home.packages = [ cdda-bin ];
  xdg.dataFile = {
    "cataclysm-dda/sound".source = cc-sounds;   
    "cataclysm-dda/config/fonts.json" = {
      source = fontsConfig;        
      force = true;
    };
    "cataclysm-dda/config/options.json" = {
      source = optionsJSON;      
      force = true;
    };
  };
}
