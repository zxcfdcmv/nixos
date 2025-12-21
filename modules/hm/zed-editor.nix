{ config, pkgs, lib, ... }:
{
  programs.zed-editor = {
    enable = true;
    extensions = [ "nix" "toml" "rust" ];
    userSettings = {
      terminal = {
        shell = "system";
      };
      show_whitespaces = "all";
    };
  };
}
