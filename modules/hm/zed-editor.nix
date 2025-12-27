{ config, pkgs, lib, ... }:
{
  programs.zed-editor = {
    enable = true;
    extensions = [ "nix" "toml" "rust" "json" ];
    userSettings = {
      terminal = {
        shell = "system";
      };
    };
  };
}
