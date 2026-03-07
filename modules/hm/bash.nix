{ config, pkgs, lib, userSettings, ... }:
{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin"
    '';
    shellAliases = {
      rg   = "rg --hidden --smart-case";
      cat  = "bat -pp";
      ls   = "eza --group-directories-first --git";
      ll   = "eza --group-directories-first --git --long --icons";
      l    = "eza --group-directories-first --git --long --icons";
      du   = "dust";
      # my-delete = "sudo nix-collect-garbage -d && nix-store --optimise";
      # my-switch = "cd ${userSettings.dotfilesDir} && nix flake update && sudo nice -n 19 ionice -c 3 nixos-rebuild switch --flake .#${userSettings.hostName}";
      my-switch = "nh os switch --update";
      my-clean = "nh clean all";
    };
  };
}
