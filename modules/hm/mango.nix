{ config, pkgs, lib, ... }:
{
  wayland.windowManager.mango = {
    enable = true;
    settings = ''
    '';
    autostart_sh = ''
      noctalia-shell &

      export QT_IM_MODULE=fcitx5 XMODIFIERS=@im=fcitx5 SDL_IM_MODULE=fcitx5 GLFW_IM_MODULE=fcitx5 GLYPH_IM_MODULE=fcitx5 && fcitx5 -d &

      foot --server &
    '';
  };  
}
