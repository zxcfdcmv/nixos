# modules/nixos/driftwm.nix
{ config, pkgs, userSettings, driftwm, ... }:

let
  finalDriftConfig = pkgs.replaceVars ../../assets/config/driftwm-config.toml {
    wallpaper = "${userSettings.dotfilesDir}/assets/config/driftwm-boho_dawn.glsl";
    footserver = "${pkgs.foot}/bin/foot";
    footclient = "${pkgs.foot}/bin/footclient";
    mako = "${pkgs.mako}/bin/mako";
    fuzzel = "${pkgs.fuzzel}/bin/fuzzel";

    xdg_desktop = "${pkgs.xdg-desktop-portal}/libexec/xdg-desktop-portal";
    xdg_wlr = "${pkgs.xdg-desktop-portal-wlr}/libexec/xdg-desktop-portal-wlr";
    xdg_gtk = "${pkgs.xdg-desktop-portal-gtk}/libexec/xdg-desktop-portal-gtk";
  };

  driftwmPkg = driftwm.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  environment.systemPackages = [ driftwmPkg ];
  
  environment.loginShellInit = ''
    if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
      exec ${driftwmPkg}/bin/driftwm
    fi
  '';

  home-manager.users.${userSettings.username} = { pkgs, config, ... }: {
    services.mako = {
      enable = true;
      settings = {
        anchor = "top-right";
        width = 350;
        height = 150;
        margin = "25,5,0,5";
        padding = "10";
    
        default-timeout = 5000;
        ignore-timeout = false;
        max-visible = 5;
    
        icons = true;
        max-icon-size = 48;
    
        on-button-left = "dismiss";
        on-button-right = "dismiss-all";
      };
    };

    xdg.configFile."driftwm/config.toml".source = finalDriftConfig;
  };
}
