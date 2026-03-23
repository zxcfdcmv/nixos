{ config, pkgs, ... }:
let

  centralWaybarConfig = pkgs.writeText "central-waybar-config" ''
    {
      "layer": "overlay",
      "position": "top",
      "width": 280,
      "height": 72,
      "margin-top": 404,
      "exclusive": false,
      "ipc": true,
    
      "modules-center": ["group/hub"],
    
      "group/hub": {
        "orientation": "vertical",
        "modules": [
          "group/tools",
          "group/scripts"
        ]
      },
    
      "group/tools": {
        "orientation": "horizontal",
        "modules": [
          "network",
          "bluetooth",
          "pulseaudio",
          "backlight"
        ]
      },
    
      "group/scripts": {
        "orientation": "horizontal",
        "modules": [
          "custom/fcitx",
          "custom/dae",
          "custom/kanata"
        ]
      },
    
      "network": {
        "format-wifi": "",
        "format-ethernet": "",
        "format-disconnected": "⚠",
        "tooltip": false,
        "on-click": "footclient -e nmtui",
        "interval": 5
      },
    
      "bluetooth": {
        "format": "{icon}",
        "format-icons": {
          "enabled": "",
          "disabled": "",
          "connected": ""
        },
        "format-disabled": "",
        "tooltip": false,
        "on-click": "footclient -e bluetuith",
        "on-click-right": "bluetooth toggle",
        "interval": 5
      },
    
      "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": " {volume}%",
        "format-icons": ["", ""],
        "tooltip": false,
        "on-click": "footclient -e pulsemixer",
        "on-click-right": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
        "on-scroll-up": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+",
        "on-scroll-down": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-"
      },
    
      "backlight": {
        "format": "{icon} {percent}%",
        "format-icons": [""],
        "tooltip": false,
        "on-scroll-up": "brightnessctl set +5%",
        "on-scroll-down": "brightnessctl set 5%-"
      },
    
      "custom/fcitx": {
        "format": "F",
        "tooltip": false,
        "on-click": "toggle-fcitx"
      },
    
      "custom/dae": {
        "format": "D",
        "tooltip": false,
        "on-click": "toggle-dae"
      },
    
      "custom/kanata": {
        "format": "K",
        "tooltip": false,
        "on-click": "toggle-kanata"
      }
    }
  '';

  centralWaybarStyle = pkgs.writeText "central-waybar-style" ''
    window#waybar {
      background: transparent;
    }

    .modules-center {
      background: transparent;
    }

    #group-hub {
      background: rgba(40, 40, 40, 0.9);
      border-radius: 5px;
      padding: 4px;
    }

    #group-tools, #group-scripts {
      background: transparent;
    }

    #network, #bluetooth {
      border-radius: 5px;
      padding: 0 8px;
      margin: 2px;
      background-color: rgba(40, 40, 40, 0.6);
      color: #ffffff;
      font-size: 14px;
      min-width: 28px;
      min-height: 28px;
    }

    #pulseaudio, #backlight {
      border-radius: 5px;
      padding: 0 10px;
      margin: 2px;
      background-color: rgba(40, 40, 40, 0.6);
      color: #ffffff;
      font-size: 13px;
      min-width: 60px;
      min-height: 28px;
    }

    #custom-fcitx, #custom-dae, #custom-kanata {
      border-radius: 5px;
      padding: 0 12px;
      margin: 2px;
      background-color: rgba(40, 40, 40, 0.6);
      color: #ffffff;
      font-size: 14px;
      min-width: 28px;
      min-height: 28px;
    }

    #network:hover, #bluetooth:hover, #pulseaudio:hover, #backlight:hover,
    #custom-fcitx:hover, #custom-dae:hover, #custom-kanata:hover {
      background-color: rgba(60, 60, 60, 0.8);
    }

    #pulseaudio.muted {
      color: #f38ba8;
    }

    #bluetooth.disabled {
      color: rgba(255, 255, 255, 0.4);
    }

    #network.disconnected {
      color: #f38ba8;
    }
  '';

  toggleCentralHub = pkgs.writeShellScriptBin "toggle-central-hub" ''
    PID=$(pgrep -f "waybar.*central-waybar-config" | head -1 || true)
    if [ -n "$PID" ]; then
      pkill -f "waybar.*central-waybar-config" 2>/dev/null || true
    else
      ${pkgs.waybar}/bin/waybar \
        -c ${centralWaybarConfig} \
        -s ${centralWaybarStyle} &
    fi
  '';
in
{
  home.packages = [ toggleCentralHub ];
}
