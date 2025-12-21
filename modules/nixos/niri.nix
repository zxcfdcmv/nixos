{ config, lib, pkgs, ... }:
{
  programs.niri.enable = true;

  services.greetd.settings.default_session.command = ''
    ${pkgs.tuigreet}/bin/tuigreet \
      --cmd "${pkgs.niri}/bin/niri --session" \
      --theme "dark" \
      --greet-align center \
      --time \
      --time-format "%A, %d %B %Y %H:%M:%S" \
      --remember \
  '';

  systemd.user = {
    extraConfig = ''
      DefaultEnvironment="XDG_CURRENT_DESKTOP=niri"
      DefaultEnvironment="XDG_SESSION_TYPE=wayland"
    '';
  };

}
