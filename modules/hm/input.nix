{ config, pkgs, lib, ... }:
{
  # 输入法框架只装一次，方案由 inputs/*.nix 提供
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
    };
  };

  xdg.configFile = {
    "fcitx5/profile" = {
      text = ''
        [Groups/0]
        Name=Default
        Default Layout=us
        DefaultIM=rime

        [Groups/0/Items/0]
        Name=rime
        Layout=

        [Groups/0/Items/1]
        Name=keyboard-us
        Layout=

        [GroupOrder]
        0=Default      
      '';
      force = true;
    };
    "fcitx5/conf/classicui.conf".text = ''
      Theme=Nord-Dark
      Font=Maple Mono NF CN 14
    '';
  };
}
