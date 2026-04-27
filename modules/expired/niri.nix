{ config, pkgs, lib, userSettings, ... }:

{
  programs.niri.enable = true;
  
  services.greetd = {
    enable = true;
    settings.default_session.command = ''
      ${pkgs.tuigreet}/bin/tuigreet \
        --cmd "${pkgs.niri}/bin/niri-session" \
        --theme "dark" \
        --greet-align center \
        --time \
        --time-format "%A, %d %B %Y %H:%M:%S" \
        --remember \
    '';
  };
  
  # --- 2. 用户级配置 (通过 home-manager.users 注入) ---
  home-manager.users.${userSettings.username} = { osConfig, ... }: {
    home.file.".config/niri/config.kdl".text = ''
      ${builtins.readFile ../../assets/niri.kdl}

      spawn-at-startup "swaybg" "-i" "${config.stylix.image}" "-m" "fill"
    '';
    home.sessionVariables = {
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_TYPE = "wayland";
      QT_QPA_PLATFORM = "wayland";
    };
  };
}
