{ config, pkgs, lib, ... }:
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-gtk
        fcitx5-rime
        fcitx5-nord
      ];

      settings = {
        inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "rime";
          };
          "Groups/0/Items/0" = {
            Name = "rime";
            Layout = "";
          };
          "GroupOrder"."0" = "Default";
        };
        
        # 可以在这里添加其他配置
        globalOptions = { };
        
        addons = {
          # Rime 或其他插件的特定配置
        };
      };
    };
  };
}
