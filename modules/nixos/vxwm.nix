{ config, pkgs, ... }:
let
  vxwm = pkgs.stdenv.mkDerivation rec {
    pname = "vxwm";
    version = "master";

    src = pkgs.fetchzip {
      url = "https://github.com/wh1tepearll/vxwm/archive/refs/heads/master.zip";
      sha256 = "sha256-W6BS8V34wCsNj2S9eg+c2YQZ80PX0MDmVZDQkSF68mA=";
    };

    # 修复上游 zoom/swapmaster 编译错误
    postPatch = ''
      # 开启自动启动
      substituteInPlace modules.def.h --replace "#define AUTOSTART 0" "#define AUTOSTART 1"
      # substituteInPlace config.def.h --replace "zoom" "swapmaster"
      cp ${../../assets/vxwm-config.h} config.def.h
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

  services.xserver.enable = true;
  services.xserver.displayManager.startx.enable = true;

  environment.loginShellInit = ''
    if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty2" ]; then
      exec startx ${vxwm}/bin/vxwm
    fi
  '';
}
