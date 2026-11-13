# modules/nixos/driftwm.nix
{ config, pkgs, userSettings, driftwm, ... }:

let
  finalDriftConfig = pkgs.replaceVars ../../assets/config/driftwm/config.toml {
    # wallpaper = "${userSettings.dotfilesDir}/assets/config/driftwm/glsl/main.glsl";
    wallpaper = "/run/user/1000/driftwm/main.glsl";
    bg_rotator = "${bgRotator}";

    foot = "${pkgs.foot}/bin/foot";
    footclient = "${pkgs.foot}/bin/footclient";
    # mako = "${pkgs.mako}/bin/mako";
    fuzzel = "${pkgs.fuzzel}/bin/fuzzel";
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
  
  # 走 driftwm 官方的 systemd 会话入口：driftwm 作为 user service 运行
  # (driftwm.service, Type=notify)，由它拉起 graphical-session.target，
  # 并在启动时把 WAYLAND_DISPLAY / XDG_CURRENT_DESKTOP 等导入 systemd --user 和
  # D-Bus 激活环境。于是 portal、mako 等全部交给 systemd/D-Bus 管理，
  # compositor 退出时也会通过 driftwm-shutdown.target 一起 teardown。
  environment.loginShellInit = ''
    if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
      ${driftBgInit}
      exec ${driftwmPkg}/bin/driftwm-session
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
