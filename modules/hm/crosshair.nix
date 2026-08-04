{ pkgs, userSettings, ... }:

let
  gocrosshair = pkgs.stdenv.mkDerivation rec {
    pname = "gocrosshair";
    version = "main";

    src = pkgs.fetchurl {
      url = "${userSettings.githubProxy}/github.com/MatheusLasserre/gocrosshair/archive/refs/heads/main.zip";
      sha256 = "sha256-m7nOrlRh1tfkJYOf7UtMff60cX3I/g/fdexE3qqJeZc=";
    };

    nativeBuildInputs = [ pkgs.unzip pkgs.go ];

    unpackPhase = ''
      unzip $src
      cd gocrosshair-main
    '';

    buildPhase = ''
      export HOME=$TMPDIR
      export CGO_ENABLED=0
      go build -ldflags="-s -w" -trimpath -o gocrosshair .
    '';

    installPhase = ''
      mkdir -p $out/bin
      cp gocrosshair $out/bin/
    '';

    meta = with pkgs.lib; {
      description = "Lightweight crosshair overlay for X11";
      homepage = "https://github.com/MatheusLasserre/gocrosshair";
      license = licenses.mit;
    };
  };
in
{
  home.packages = [ gocrosshair ];
}
