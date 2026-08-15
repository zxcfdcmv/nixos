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
      ll   = "eza --group-directories-first --git --long --icons=auto";
      l    = "eza --group-directories-first --git --long --icons=auto";
      du   = "dust";

      kubectl = "sudo -E kubectl";
      my-clean = "cd ${userSettings.dotfilesDir} && nh clean all && nh os boot .";
      kanata = "sudo -E kanata -c";

      croc-s = "CROC_SECRET=${userSettings.username} croc send";
      croc-r = "CROC_SECRET=${userSettings.username} croc --yes --overwrite --out /home/${userSettings.username}/Downloads/";
    };
  };
}
