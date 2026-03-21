{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    swaybg
    # pwvucontrol
    # blueman
    # networkmanagerapplet
    pulsemixer
    bluetuith
    brightnessctl
    wlogout
  ];

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    style = ''
      window#waybar {
        background: transparent;
      }

      /* ========== niri/workspaces 样式 ========== */
       .modules-center #workspaces button {
        border-radius: 5px;
        padding: 0 8px;
        margin: 5px 5px 0 0;
        background-color: rgba(40, 40, 40, 0.25);
        color: #ffffff;
        transition: none;
        border: none;
        box-shadow: none;
        border-bottom: none;  /* 明确去掉底部边框 */
      }

      .modules-center #workspaces button.active {
        background-color: rgba(40, 40, 40, 0.25);
        color: #ffffff;
        box-shadow: none;
        border: none;
        border-bottom: none;  /* 再次确保 */
      }

      .modules-center #workspaces button.focused {
        background-color: rgba(40, 40, 40, 0.6);
        color: #ffffff;
        box-shadow: none;
        border: none;
        border-bottom: none;
      }

      /* 覆盖所有状态 */
      .modules-center #workspaces button:hover,
      .modules-center #workspaces button.urgent,
      .modules-center #workspaces button.empty {
        box-shadow: none;
        border: none;
        border-bottom: none;
        text-decoration: none;
        background-image: none;
      } 

      /* ========== 其他模块保持原有样式 ========== */
      /* 胶囊形按钮 */
      #hardware,
      #window,
      #custom-media {
        border-radius: 5px;       /* 胶囊圆角 */
        padding: 0 8px ;
        margin: 5px 0 0 5px;
        background-color: rgba(40, 40, 40, 0.6); /* 半透明胶囊 */
        color: #ffffff;
        transition: none;          /* 去掉动画 */
      }

      #tray,
      #system,
      #custom-power {
        border-radius: 5px;       /* 胶囊圆角 */
        padding: 0 8px ;
        margin: 5px 5px 0 0;
        background-color: rgba(40, 40, 40, 0.6); /* 半透明胶囊 */
        color: #ffffff;
        transition: none;          /* 去掉动画 */
      }
    '';

    settings = [{
      layer = "top";
      position = "top";
      modules-left = [
        "group/hardware"
        "niri/mode"
        "niri/window"
        "custom/media"
      ];
      modules-center = ["niri/workspaces"];
      modules-right = [
        "tray"
        "group/system"
        "custom/power"
      ];

      "group/hardware" = {
        orientation = "horizontal";
        modules = [
          "memory"
          "cpu"
          "temperature"
        ];
        drawer = {
          transition-duration = 500;
          children-class = "hardware-child";
          transition-left-to-right = true;
        };
      };

      "group/system" = {
        orientation = "horizontal";
        modules = [
          "clock"
          "pulseaudio"
          "backlight"
          "network"
          "bluetooth"
          "battery"
          "custom/notification"
        ];
        drawer = {
          transition-duration = 500;
          children-class = "hardware-child";
          transition-left-to-right = false;
        };
      };

      network = {
        format-wifi = " {signalStrength}%";
        format-ethernet = " {ifname}";
        format-disconnected = "⚠";
        tooltip-format = "{essid} | {ipaddr}/{cidr}";
        on-click = "footclient -e nmtui";
        on-click-right = "nmcli networking off";
        interval = 5;
      };

      bluetooth = {
        format = "{icon}";
        format-icons = {
          enabled = "";
          disabled = "";
          connected = " {num_connections}";
        };
        format-disabled = "";
        tooltip-format = "{controller_alias}\n{num_connections} devices";
        on-click = "footclient -e bluetuith";
        on-click-right = "bluetooth toggle";
        interval = 5;
      };

      "custom/notification" = {
        format = " ";
        on-click = "makoctl restore";
        on-click-right = "makoctl dismiss --all";
        tooltip = false;
      };

      battery = {
        format = "{icon} {capacity}%";
        format-icons = ["" "" "" "" ""];
        tooltip = false;
      };

       pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "";
        format-icons = ["" "" ""];
        on-click = "footclient -e pulsemixer";      # ← TUI 音频控制
        on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+";
        on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-";
      };     

      backlight = {
        format = "{icon} {percent}%";
        format-icons = ["" ""];
        on-scroll-up = "brightnessctl set +5%";
        on-scroll-down = "brightnessctl set 5%-";
        tooltip = false;
      };      

      clock = {
        format = "{:%Y-%m-%d %H:%M}";
        tooltip = false;
      };

      "custom/power" = {
        format = "⏻";
        on-click = "wlogout";  # 或自定义脚本
        tooltip = false;
      };
    }];
  };

  services.mako = {
    enable = true;
    settings = {
      anchor = "top-right";
      width = 350;
      height = 150;
      margin = "10,10";
      padding = "10";
    
      default-timeout = 5000;
      ignore-timeout = false;
      max-visible = 5;
    
      icons = true;
      max-icon-size = 48;
    
      on-button-left = "dismiss";
      on-button-right = "dismiss-all";
    };
  };
}
