{ config, pkgs, ... }:
let
  customCommands = [
    "toggle-fcitx"
    "toggle-dae"
    "toggle-kanata"
    "cs2-cn"
    "cs2-global"
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
      ${pkgs.libnotify}/bin/notify-send -u "$urgency" -i input-keyboard "$title"
    }

    case "$STATUS" in
      active)
        $CMD stop "$SERVICE"
        notify "$SERVICE Disabled" "normal"
        ;;
      *)
        $CMD start "$SERVICE"
        notify "$SERVICE Enabled" "low"
        ;;
    esac
  '';

  mkFcitx5ToggleService = pkgs.writeShellScriptBin "toggle-fcitx" ''
      notify() {
        local title="$1"
        local urgency="$2"
        # noctalia-shell ipc call toast send "{\"title\":\"$title\",\"type\":\"$type\"}"
        ${pkgs.libnotify}/bin/notify-send -u "$urgency" -i input-keyboard "$title"
      }

      if pidof fcitx5 >/dev/null 2>&1; then
          pkill fcitx5
          sleep 0.5
          if pidof fcitx5 >/dev/null 2>&1; then
              pkill -9 fcitx5
          fi
          notify "Fcitx5 Disabled" "normal"
      else
          fcitx5 -d
          notify "Fcitx5 Enabled" "low"
      fi
  '';
in
{
  home.packages = (with pkgs; [
    mkFcitx5ToggleService

    # toggle-dae - 系统服务
    (mkSystemToggleService "toggle-dae" "dae")

    # toggle-kanata - 系统服务
    (mkSystemToggleService "toggle-kanata" "kanata-default")

    (writeShellScriptBin "rust-project-gui" ''
      exec nix-shell ~/nixos/modules/project/rust-gui.nix
    '') 

    (writeShellScriptBin "rust-project-cli" ''
      exec nix-shell ~/nixos/modules/project/rust-cli.nix
    '') 
  
    (writeShellScriptBin "cs2-cn" ''
      gamemoderun steam -applaunch 730 -novid -perfectworld +exec autoexec.cfg
    '') 
    (writeShellScriptBin "cs2-global" ''
      gamemoderun steam -applaunch 730 -novid +exec autoexec.cfg
    '') 
  ])
  ++ builtins.map mkDesktop customCommands;  
}
