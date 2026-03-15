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
      local type="$2"
      noctalia-shell ipc call toast send "{\"title\":\"$title\",\"type\":\"$type\"}"
    }

    case "$STATUS" in
      active)
        $CMD stop "$SERVICE"
        notify "$SERVICE Disabled" "warning"
        ;;
      *)
        $CMD start "$SERVICE"
        notify "$SERVICE Enabled" "success"
        ;;
    esac
  '';

  mkFcitx5ToggleService = pkgs.writeShellScriptBin "toggle-fcitx" ''
      notify() {
        local title="$1"
        local type="$2"
        noctalia-shell ipc call toast send "{\"title\":\"$title\",\"type\":\"$type\"}"
      }

      if pidof fcitx5 >/dev/null 2>&1; then
          pkill fcitx5
          sleep 0.5
          if pidof fcitx5 >/dev/null 2>&1; then
              pkill -9 fcitx5
          fi
          notify "Fcitx5 Disabled" "warning"
      else
          fcitx5 -d
          notify "Fcitx5 Enabled" "success"
      fi
  '';
in
{
  home.packages = (with pkgs; [
    # toggle-fuzzel
    (writeShellScriptBin "toggle-fuzzel" ''
      if pgrep -x "fuzzel" > /dev/null; then
        pkill -x "fuzzel"
      else
        ${pkgs.fuzzel}/bin/fuzzel
      fi
    '')

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
