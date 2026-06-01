{ config, pkgs, lib, userSettings, ... }:
{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin"
    '';
    initExtra = ''
      export LC_MESSAGES="en_US.UTF-8"
    '';
    shellAliases = {
      rg   = "rg --hidden --smart-case";
      cat  = "bat -pp";
      ls   = "eza --group-directories-first --git";
      ll   = "eza --group-directories-first --git --long --icons";
      l    = "eza --group-directories-first --git --long --icons";
      du   = "dust";

      kubectl = "sudo -E kubectl";

      # my-delete = "sudo nix-collect-garbage -d && nix-store --optimise";
      my-clean = "nh clean all && nh os boot";
      kanata = "sudo -E kanata -c";
    };
  };
}
