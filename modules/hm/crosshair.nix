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
in
{
  home.packages = [ gocrosshair ];
}
