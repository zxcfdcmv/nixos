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
