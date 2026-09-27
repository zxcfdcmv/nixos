# modules/nixos/driftwm.nix
{ config, pkgs, userSettings, driftwm, ... }:

let
  finalDriftConfig = pkgs.replaceVars ../../assets/config/driftwm/config.toml {
    # wallpaper = "${userSettings.dotfilesDir}/assets/config/driftwm/glsl/main.glsl";
    wallpaper = "/run/user/1000/driftwm/main.glsl";
    bg_rotator = "${bgRotator}";

    footserver = "${pkgs.foot}/bin/foot";
    footclient = "${pkgs.foot}/bin/footclient";
    mako = "${pkgs.mako}/bin/mako";
    fuzzel = "${pkgs.fuzzel}/bin/fuzzel";

    xdg_desktop = "${pkgs.xdg-desktop-portal}/libexec/xdg-desktop-portal";
    xdg_wlr = "${pkgs.xdg-desktop-portal-wlr}/libexec/xdg-desktop-portal-wlr";
    xdg_gtk = "${pkgs.xdg-desktop-portal-gtk}/libexec/xdg-desktop-portal-gtk";
  };

  driftBgInit = pkgs.writeShellScript "driftwm-bg-init" ''
    SRC_GLSL_DIR="${userSettings.dotfilesDir}/assets/config/driftwm/glsl"
    TARGET_GLSL_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/driftwm"
    mkdir -p "$TARGET_GLSL_DIR"

    [ -d "$SRC_GLSL_DIR" ] || exit 0
    TARGET_FILE=$(CDPATH= cd "$SRC_GLSL_DIR" && ${pkgs.coreutils}/bin/ls *.glsl | ${pkgs.coreutils}/bin/shuf -n 1)
    [ -n "$TARGET_FILE" ] || exit 0
    ${pkgs.coreutils}/bin/cp "$SRC_GLSL_DIR/$TARGET_FILE" "$TARGET_GLSL_DIR/main.glsl"
  '';

  # glsl轮换脚本
  bgRotator = pkgs.writeShellScript "driftwm-bg-rotator" ''
    SRC_GLSL_DIR="${userSettings.dotfilesDir}/assets/config/driftwm/glsl"
    TARGET_GLSL_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/driftwm"
    mkdir -p "$TARGET_GLSL_DIR"

    while true; do
      ${pkgs.coreutils}/bin/sleep 600

      TARGET_FILE=$(CDPATH= cd "$SRC_GLSL_DIR" && ${pkgs.coreutils}/bin/ls *.glsl | ${pkgs.coreutils}/bin/shuf -n 1)
      if [ -n "$TARGET_FILE" ]; then
        ${pkgs.coreutils}/bin/cp "$SRC_GLSL_DIR/$TARGET_FILE" "$TARGET_GLSL_DIR/main.glsl"
        ${driftwmPkg}/bin/driftwm msg action reload-config
      fi
    done
  '';  

  driftwmPkg = driftwm.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  environment.systemPackages = [ driftwmPkg ];
  
  environment.loginShellInit = ''
    if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
      ${driftBgInit}
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
