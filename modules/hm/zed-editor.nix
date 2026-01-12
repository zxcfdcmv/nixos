{ config, pkgs, lib, ... }:
{
  programs.zed-editor = {
    enable = true;
    userSettings = {
      ui_font_family = "Maple Mono NF CN";
      ui_font_size = 16;
      buffer_font_family = "Maple Mono NF CN";
      buffer_font_size = 16;
      theme = {
        mode = "system";
        dark = "one Dark";
        light = "one Light";
      };
      terminal = {
        env = { TERM = "footclient"; };
        font_family = "Maple Mono NF CN";
        font_size = 16;
        shell = "system";
      };
      autosave = "on_focus_change";
      load_direnv = "shell_hook";
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
    };
  };
}
