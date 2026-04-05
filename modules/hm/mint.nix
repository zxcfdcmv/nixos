{ pkgs, userSettings, ... }:

let
  drg-version = "0.2.10";

  drg-src = pkgs.fetchurl {
    url = "${userSettings.githubProxy}/https://github.com/trumank/mint/releases/download/v${drg-version}/drg_mod_integration-x86_64-unknown-linux-gnu.tar.xz";
    sha256 = "sha256-Ukpa/tvFUXZNvRPUo6CPwQiIt/yWLREdvAu1S8b/eyw=";
  };

  drg = pkgs.stdenv.mkDerivation {
    pname = "drg-mod-integration";
    version = drg-version;

    src = drg-src;

    nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];

    buildInputs = with pkgs; [
      gtk3 glib openssl_1_1 stdenv.cc.cc.lib
      libx11 libxcb libxcursor libxi libxrandr libxext
      libxkbcommon libxrender libxfixes libxcomposite libxdamage libxinerama
      zlib libglvnd mesa
    ];

    installPhase = ''
      mkdir -p $out/bin
      find . -maxdepth 1 -type f -executable -exec cp {} $out/bin/ \;
    '';

    postFixup = ''
      wrapProgram $out/bin/drg_mod_integration \
        --prefix WINIT_UNIX_BACKEND : "x11" \
        --prefix __EGL_VENDOR_LIBRARY_FILENAMES : "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json" \
        --set LD_LIBRARY_PATH ${pkgs.lib.makeLibraryPath (with pkgs; [ libX11 libxcb libXext libXi libXrandr libGL mesa ])} \
        --set LIBGL_DRIVERS_PATH /run/opengl-driver/lib/dri \
        --set MESA_LOADER_DRIVER_OVERRIDE iris
    '';
  };

in {
  home = {
    packages = [ drg ];    
    file.".config/drg-mod-integration/mod_data.json" = {
      source = ../../assets/drg-mod-config.json;
    };
  };
}
