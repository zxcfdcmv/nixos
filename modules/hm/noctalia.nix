{ pkgs, noctalia, userSettings, ... }:
{
  imports = [
    noctalia.homeModules.default
  ];
  programs.noctalia-shell = {
    enable = true;
    settings = {
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
            }
            {
              id = "ActiveWindow";
              showIcon = true;
              maxWidth = 145;
            }
            {
              id = "MediaMini";
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
        avatarImage = "${userSettings.dotfilesDir}/assets/pictures/.face";
        radiusRatio = 0.2;
        animationDisabled = true;  # 跳过所有动画
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
        directory = "${userSettings.dotfilesDir}/assets/pictures";
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
        yazi = true;
        helix = true;
      };
      nightLight.enabled = true;
      controlCenter = {
        position = "close_to_bar_button";
        shortcuts = {
          left = [
            {
              id = "WiFi";
            }
            {
              id = "Bluetooth";
            }
            {
              id = "ScreenRecorder";
            }
            {
              id = "WallpaperSelector";
            }
          ];
          right = [
            {
              id = "Notifications";
            }
            {
              id = "PowerProfile";
            }
            {
              id = "KeepAwake";
            }
            {
              id = "NightLight";
            }
          ];
        };
        cards = [
          {
            enabled = true;
            id = "profile-card";
          }
          {
            enabled = true;
            id = "shortcuts-card";
          }
          {
            enabled = false;
            id = "audio-card";
          }
          {
            enabled = true;
            id = "brightness-card";
          }
          {
            enabled = true;
            id = "weather-card";
          }
          {
            enabled = true;
            id = "media-sysmon-card";
          }
        ];
      };
    };
  };
}
