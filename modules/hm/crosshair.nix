{ pkgs, userSettings, lib, ... }:

let
  gocrosshair = pkgs.buildGoModule rec {
    pname = "gocrosshair";
    version = "main";

    src = pkgs.fetchurl {
      url = "${userSettings.githubProxy}/github.com/MatheusLasserre/gocrosshair/archive/refs/heads/main.tar.gz";
      sha256 = "sha256-/L3TGJ4NXSSbkguBHEjDVQfME8KsFcReWjuIDuc/I3M=";
    };

    sourceRoot = "gocrosshair-main";

    vendorHash = "sha256-4NiPgMjnancKpKsHAAKlSz0eUJTeDPjMm/8G2ryfDrY=";

    ldflags = [ "-s" "-w" ];
    env.CGO_ENABLED = "0";

    env.GOPROXY = "https://goproxy.cn,direct";
    env.GOSUMDB = "off";

    meta = with lib; {
      description = "Lightweight crosshair overlay for X11";
      homepage = "https://github.com/MatheusLasserre/gocrosshair";
      license = licenses.mit;
    };
  };

  wayland-crosshair = pkgs.stdenv.mkDerivation rec {
    pname = "wayland-crosshair";
    version = "master";

    src = pkgs.fetchurl {
      url = "https://github.com/Divvv/wayland-crosshair/archive/refs/heads/master.zip";
      sha256 = "sha256-ZghgGY5vSnjxr9StQxn/VqPOaEnHn9AONHSmyXt+gdk="; 
    };

    nativeBuildInputs = [ pkgs.pkg-config pkgs.unzip ];

    buildInputs = [ 
      pkgs.wayland 
      pkgs.wayland-protocols 
      pkgs.libxkbcommon 
      pkgs.cairo 
      pkgs.gtk3 
      pkgs.gtk-layer-shell 
      pkgs.wlsunset
    ];

    buildPhase = ''
      make CFLAGS="$(pkg-config --cflags gtk+-3.0 gtk-layer-shell-0) -O2" \
           LIBS="$(pkg-config --libs gtk+-3.0 gtk-layer-shell-0)"
    '';

    # 规范安装路径，并将 crosshair 改名为 wayland-crosshair
    installPhase = ''
      mkdir -p $out/bin
      cp crosshair $out/bin/wayland-crosshair
    '';
  };
in
{
  home.packages = [
    gocrosshair
    wayland-crosshair
  ];
}
