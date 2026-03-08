{ config, pkgs, ... }:
let
  customCommands = [
    "toggle-dae"
    "toggle-kanata"
    "cs2-cn"
    "cs2-global"
  ];

  mkDesktop = cmd: pkgs.makeDesktopItem {
    name = cmd;
    desktopName = cmd;
    exec = cmd;
    terminal = false;
    categories = [ "Utility" ];
  };

  mkToggleService = name: service: pkgs.writeShellScriptBin name ''
    SERVICE="${service}.service"
    STATUS=$(systemctl is-active "$SERVICE" 2>/dev/null || echo "inactive")

    notify() {
      local title="$1"
      local type="$2"
      noctalia-shell ipc call toast send "{\"title\":\"$title\",\"type\":\"$type\"}"
    }

    case "$STATUS" in
      active)
        sudo systemctl stop "$SERVICE"
        notify "$SERVICE Disabled" "warning"
        ;;
      *)
        sudo systemctl start "$SERVICE"
        notify "$SERVICE Enabled" "success"
        ;;
    esac
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

    # toggle-dae
    (mkToggleService "toggle-dae" "dae")   

    # toggle-kanata
    (mkToggleService "toggle-kanata" "kanata-default")

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
  ])
  ++ builtins.map mkDesktop customCommands;  
}
