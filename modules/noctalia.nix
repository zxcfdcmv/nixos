{ pkgs, noctalia, ... }:
{
  imports = [
    noctalia.homeModules.default
  ];
  programs.noctalia-shell = {
    enable = true;
    settings = {
      # configure noctalia here; defaults will
      # be deep merged with these attributes.
      bar = {
        density = "comfortable";
        position = "top";
        showCapsule = true;
        floating = true;
        capsuleOpacity = 0.6;
        backgroundOpacity = 0;
        widgets = {
          left = [
            {
              id = "SystemMonitor";
              showCpuUsage = true;
              showMemoryUsage = true;
              showMemoryAsPercentage = true;
            }
            {
              id = "ActiveWindow";
              showIcon = true;
              maxWidth = 145;
            }
            {
              id = "MediaMini";
              maxWidth = 145;
            }
          ];
          center = [
            {
              hideUnoccupied = false;
              id = "Workspace";
              labelMode = "name";
            }
          ];
          right = [
            { id = "Tray"; }
            { id = "Volume"; }
            {
              alwaysShowPercentage = false;
              id = "Battery";
              warningThreshold = 30;
            }
            {
              formatHorizontal = "HH:mm ddd, MMM dd";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
          ];
        };
      };
      colorSchemes = {
        darkMode = true;
        predefinedScheme = "Ayu";
        
      };
      location = {
        name = "jinan";
      };
      general = {
        avatarImage = "/home/zxcfdcmv/nixos/assets/pictures/.face";
        radiusRatio = 0.2;
        animationDisabled = true;  # 跳过所有动画
        animationSpeed = 2;        # 动画速度, 数值越大动画越快
        language = "zh-CN";
        enableShadows = false;
      };
      ui = {
        fontDefault = "Maple Mono NF CN";
        fontFixed = "Maple Mono NF CN";
        backgroundOpacity = 0.60;   # Noctalia 半透明
        blurEnabled = false;        # Niri 不支持模糊
        panelRadius = 18;        
        panelBackgroundOpacity = 0;
      };
      wallpaper = {
        enabled = true;
        directory = "/home/zxcfdcmv/nixos/assets/pictures";
        randomEnabled = true;
        hideWallpaperFilenames = true;
        transitionType = "none";
      };
      dock.enabled = false;
      templates = {
        gtk = true;
        qt = true;
        kcolorscheme = true;
        foot = true;
        fuzzel = true;
        niri = true;
      };
      nightLight.enabled = true;
    };
  };
}
