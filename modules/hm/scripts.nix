{ config, pkgs, ... }:
{
  home.packages = with pkgs; [

    # fuzzel-toggle
    (writeShellScriptBin "fuzzel-toggle" ''
      if pgrep -x "fuzzel" > /dev/null; then
        pkill -x "fuzzel"
      else
        ${pkgs.fuzzel}/bin/fuzzel
      fi
    '')

    # dae-toggle
    (writeShellScriptBin "dae-toggle" ''
      SERVICE="dae.service"
      STATUS=$(systemctl is-active "$SERVICE" 2>/dev/null || echo "inactive")

      notify() {
        local title="$1"
        local body="$2"
        local type="$3"
        noctalia-shell ipc call toast send "{\"title\":\"$title\",\"body\":\"$body\",\"type\":\"$type\"}"
      }

      case "$STATUS" in
        active)
          sudo systemctl stop "$SERVICE"
          notify "Proxy Disabled" "Connection is now direct\nDaemon: $SERVICE" "warning"
          ;;
        *)
          sudo systemctl start "$SERVICE"
          notify "Proxy Enabled" "Traffic routing active\nDaemon: $SERVICE" "notice"
          ;;
      esac
    '')

    # rust-project-gui
    (writeShellScriptBin "rust-project-gui" ''
      exec nix-shell ~/nixos/modules/project/rust-gui.nix
    '') 

    # rust-project-cli
    (writeShellScriptBin "rust-project-cli" ''
      exec nix-shell ~/nixos/modules/project/rust-cli.nix
    '') 
  
    # cs2-cn
    (writeShellScriptBin "cs2-cn" ''
      gamemoderun steam -applaunch 730 -novid -perfectworld +exec autoexec.cfg
    '') 
    # cs2-global
    (writeShellScriptBin "cs2-global" ''
      gamemoderun steam -applaunch 730 -novid +exec autoexec.cfg
    '') 

  ];
}
