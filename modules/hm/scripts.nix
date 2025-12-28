{ config, pkgs, ... }:
{
  home.packages = with pkgs; [

    # 终端代理重建系统
    (writeShellScriptBin "my-switch-proxy" ''
      #!/usr/bin/env bash
      export http_proxy=http://127.0.0.1:7890
      export https_proxy=$http_proxy
      sudo nixos-rebuild switch --flake /home/zxcfdcmv/nixos#nixos
    '')

    # fuzzel-toggle
    (writeShellScriptBin "fuzzel-toggle" ''
      if pgrep -x "fuzzel" > /dev/null; then
        pkill -x "fuzzel"
      else
        ${pkgs.fuzzel}/bin/fuzzel
      fi
    '')

     # rust-project
    (writeShellScriptBin "rust-project-gui" ''
      exec nix-shell ~/nixos/modules/project/rust-gui.nix
    '') 
  
  ];
}
