{ config, pkgs, userSettings, ... }:
let
  customCommands = [
    "toggle-fcitx"
    "toggle-dae"
    "game-cs2-cn"
    "game-cs2-global"
    "game-low"
    "game-high"
    "cdda"
  ];

  mkDesktop = cmd: pkgs.makeDesktopItem {
    name = cmd;
    desktopName = cmd;
    exec = cmd;
    terminal = false;
    categories = [ "Utility" ];
  };

  mkSystemToggleService = name: service: pkgs.writeShellScriptBin name ''
    SERVICE="${service}.service"
    CMD="sudo systemctl"
    
    STATUS=$($CMD is-active "$SERVICE" 2>/dev/null || echo "inactive")

    notify() {
      local title="$1"
      local urgency="$2"
      # noctalia-shell ipc call toast send "{\"title\":\"$title\",\"type\":\"$type\"}"
      ${pkgs.libnotify}/bin/notify-send -u "$urgency" "$title"
    }

    case "$STATUS" in
      active)
        $CMD stop "$SERVICE"
        notify "⚫ $SERVICE Disabled" "low"
        ;;
      *)
        $CMD start "$SERVICE"
        notify "🟢 $SERVICE Enabled" "normal"
        ;;
    esac
  '';

  mkFcitx5ToggleService = pkgs.writeShellScriptBin "toggle-fcitx" ''
    notify() {
      local title="$1"
      local urgency="$2"
      # noctalia-shell ipc call toast send "{\"title\":\"$title\",\"type\":\"$type\"}"
      ${pkgs.libnotify}/bin/notify-send -u "$urgency" "$title"
    }

    if pidof fcitx5 >/dev/null 2>&1; then
        pkill fcitx5
        sleep 0.5
        if pidof fcitx5 >/dev/null 2>&1; then
            pkill -9 fcitx5
        fi
        notify "⚫ Fcitx5 Disabled" "low"
    else
        fcitx5 -d
        notify "🟢 Fcitx5 Enabled" "normal"
    fi
  '';
in
{
  home.packages = (with pkgs; [
    mkFcitx5ToggleService

    # toggle-dae - 系统服务
    (mkSystemToggleService "toggle-dae" "dae")

    (writeShellScriptBin "rust-project-gui" ''
      exec nix-shell ~/nixos/modules/project/rust-gui.nix
    '') 

    (writeShellScriptBin "rust-project-cli" ''
      exec nix-shell ~/nixos/modules/project/rust-cli.nix
    '') 
  
    (writeShellScriptBin "game-cs2-cn" ''
      steam -applaunch 730 -novid -perfectworld +exec autoexec.cfg
    '') 
    (writeShellScriptBin "game-cs2-global" ''
      steam -applaunch 730 -novid +exec autoexec.cfg
    '') 

    # x11
    (writeShellScriptBin "game-low" ''
      ${pkgs.linuxPackages.nvidia_x11.settings}/bin/nvidia-settings --assign CurrentMetaMode="DP-2: 1920x1080 @800x600 +0+0 {ViewPortIn=800x600, ViewPortOut=1920x1080+0+0, ResamplingMethod=Bilinear}"
    '')

    (writeShellScriptBin "game-high" ''
      ${pkgs.linuxPackages.nvidia_x11.settings}/bin/nvidia-settings --assign CurrentMetaMode="DP-2: 1920x1080 @1920x1080 +0+0 {ViewPortIn=1920x1080, ViewPortOut=1920x1080+0+0}"
    '')

    (writeShellScriptBin "my-switch" ''
      cd ${userSettings.dotfilesDir}
      git add .
      nh os switch . --update
    '') 

    (writeShellScriptBin "my-switch-bak" ''
      cd ${userSettings.dotfilesDir}
      git add .
      nix flake update
      sudo nice -n 19 ionice -c 3 nixos-rebuild switch --flake .#${userSettings.hostName}
    '') 

    (writeShellScriptBin "kanata-l4d2" ''
      cd ${userSettings.dotfilesDir}
      sudo -E ${pkgs.kanata}/bin/kanata -c assets/kanata/l4d2/l4d2-mouse.kbd &
      PID_MOUSE=$!
      sudo -E ${pkgs.kanata}/bin/kanata -c assets/kanata/l4d2/l4d2-bhop.kbd &
      PID_BHOP=$!
      trap 'kill $PID_MOUSE $PID_BHOP 2>/dev/null' EXIT
      wait
    '')
  ])
  ++ builtins.map mkDesktop customCommands;  
}
