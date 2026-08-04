{ config, pkgs, userSettings, ... }:
let
  vxwmConfig = pkgs.replaceVars ../../assets/vxwm-config.h {
    xdg_gtk = "${pkgs.xdg-desktop-portal-gtk}/libexec/xdg-desktop-portal-gtk";
    xdg_wlr = "${pkgs.xdg-desktop-portal-wlr}/libexec/xdg-desktop-portal-wlr";
    hsetroot = "${pkgs.hsetroot}/bin/hsetroot";
    dunst = "${pkgs.dunst}/bin/dunst";
    stylix_image = "${config.stylix.image}";
    font = "Maple Mono NF CN";
  };

  vxwm = pkgs.stdenv.mkDerivation rec {
    pname = "vxwm";
    version = "master";

    src = pkgs.fetchzip {
      url = "${userSettings.githubProxy}/https://github.com/wh1tepearll/vxwm/archive/refs/heads/master.zip";
      sha256 = "sha256-YUDkr2J4tR59Nx9MdO28NkvE5xlDUAZ5Pnmd23nwcHE=";
    };

    # 修复上游 zoom/swapmaster 编译错误
    postPatch = ''
      # 开启自动启动
      substituteInPlace modules.def.h --replace "#define AUTOSTART 0" "#define AUTOSTART 1"
      # substituteInPlace config.def.h --replace "zoom" "swapmaster"
      cp ${vxwmConfig} config.def.h     
    '';

    buildInputs = with pkgs; [
      libx11
      libxft
      libxinerama
    ];

    nativeBuildInputs = with pkgs; [ gnumake ];

    makeFlags = [ "PREFIX=$(out)" ];
  };

in
{
  environment.systemPackages = with pkgs; [
    vxwm
    xinit
  ];

  services.xserver = {
    enable = true;    
    dpi = 96;
    displayManager.startx.enable = true;
  };

  environment.loginShellInit = ''
    if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty2" ]; then
      exec startx ${vxwm}/bin/vxwm
    fi
  '';

  home-manager.users.${userSettings.username} = { pkgs, config, ...}: {
    services.dunst = {
      enable = true;
      settings = {
        global = {
          width = 350;
          height = 150;
          offset = "25x25";
          padding = 10;
          horizontal_padding = 10;
      
          timeout = 5;
          max_icon_size = 48;
          icon_position = "left";
      
          # 点击行为
          mouse_left_click = "close_current";
          mouse_right_click = "close_all";
        };
      };
    };
  };
}
