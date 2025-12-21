{ config, lib, pkgs, mango, ... }:
{
  programs.mango.enable = true;

  services.greetd.settings.default_session.command = ''
    ${pkgs.tuigreet}/bin/tuigreet \
      --cmd "${mango.packages.${pkgs.stdenv.hostPlatform.system}.mango}/bin/mango" \
      --theme "dark" \
      --greet-align center \
      --time \
      --time-format "%A, %d %B %Y %H:%M:%S" \
      --remember \
      --remember-session
  '';

  systemd.user = {
    extraConfig = ''
      DefaultEnvironment="XDG_CURRENT_DESKTOP=mango"
      DefaultEnvironment="XDG_SESSION_TYPE=wayland"
    '';
  };

}
