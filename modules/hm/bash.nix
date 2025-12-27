{ config, pkgs, lib, ... }:
{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin"
    '';
    initExtra = ''
      eval "$(zoxide init bash)"
      eval "$(fzf --bash)" 2>/dev/null || true
    '';
    shellAliases = {
      rg   = "rg --hidden --smart-case";
      cat  = "bat -pp";
      ls   = "eza --group-directories-first --git";
      ll   = "eza --group-directories-first --git --long --icons";
      l    = "eza --group-directories-first --git --long --icons";
      du   = "dust";
      # ps   = "procs";
      top  = "btm";
      z    = "zoxide query --interactive";
      delete = "sudo nix-collect-garbage -d";
      build  = "sudo nixos-rebuild build --flake ~/nixos#nixos";
      switch = "sudo nixos-rebuild switch --flake ~/nixos#nixos";
      switch-proxy = "sudo -E bash -c 'export http_proxy=http://127.0.0.1:7890 && export https_proxy=$http_proxy && nixos-rebuild switch --flake /home/zxcfdcmv/nixos#nixos'";
    };
  };
}
