{ pkgs, config, userSettings, ... }:

let
  mint-notag-version = "0.3.4";

  mint-notag-src = pkgs.fetchzip {
    url = "https://github.com/Strappazzon/drg-mint-notag/releases/download/v${mint-notag-version}/mint-x86_64-unknown-linux-gnu.zip";
    sha256 = "sha256-ABdL2NTUBqbiLBJx/fi4nA97cuIjJdyuZURTDHGY6IE=";
    stripRoot = false;
  };

  mint-notag = pkgs.stdenv.mkDerivation {
    pname = "drg-mint-notag";
    version = mint-notag-version;

    src = mint-notag-src;

    nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper pkgs.unzip ];

    buildInputs = with pkgs; [
      gtk3 glib stdenv.cc.cc.lib
      libx11 libxcb libxcursor libxi libxrandr libxext
      libxkbcommon libxrender libxfixes libxcomposite libxdamage libxinerama
      zlib libglvnd mesa
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp mint $out/bin/mint-notag
      chmod +x $out/bin/mint-notag
    '';

    postFixup = ''
      wrapProgram $out/bin/mint-notag \
        --prefix WINIT_UNIX_BACKEND : "x11" \
        --prefix __EGL_VENDOR_LIBRARY_FILENAMES : "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json" \
        --set LD_LIBRARY_PATH ${pkgs.lib.makeLibraryPath (with pkgs; [ 
          libX11 libxcb libXext libXi libXrandr libGL mesa libxkbcommon 
        ])} \
        --set LIBGL_DRIVERS_PATH /run/opengl-driver/lib/dri \
        --set MESA_LOADER_DRIVER_OVERRIDE iris
    '';
  };

in {
  home = {
    packages = [ mint-notag ];
    
    file.".config/drg-mod-integration/mod_data.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "/home/${userSettings.username}/nixos/assets/games/drg/mint-notag.json";
      force = true;
    };
  };
}
