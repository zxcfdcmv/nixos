{ pkgs, lib, config, userSettings, ... }:

let
  fireaxe-version = "0.7.3";

  fireaxe-src = pkgs.fetchurl {
    url = "${userSettings.githubProxy}/github.com/ktxiaok/FireAxe/releases/download/${fireaxe-version}/FireAxe-${fireaxe-version}-linux-x64.zip";
    hash = "sha256-5cWnvAPX1+CG761cHokSwN7gywGhcT2OY5n5VIY2Lyk=";
  };

  fireaxe = pkgs.runCommand "fireaxe-${fireaxe-version}" {
    nativeBuildInputs = [ pkgs.unzip pkgs.makeWrapper ];
  } ''
    mkdir -p $out/lib/fireaxe $out/bin
    ${pkgs.unzip}/bin/unzip -q ${fireaxe-src} -d $out/lib/fireaxe/
    mv $out/lib/fireaxe/FireAxe $out/lib/fireaxe/FireAxe.bin

    makeWrapper $out/lib/fireaxe/FireAxe.bin $out/bin/fireaxe \
      --run 'mkdir -p "$HOME/.local/share/fireaxe"' \
      --run 'cd "$HOME/.local/share/fireaxe"'
  '';

  configRoot = "/home/${userSettings.username}/nixos/assets/l4d2";

in {
  home.packages = [ fireaxe ];

  home.file = {
    ".local/share/fireaxe/FireAxe/Settings.json".source = 
      config.lib.file.mkOutOfStoreSymlink "${configRoot}/fireaxe-settings.json";

    ".local/share/fireaxe/.addonroot".source = 
      config.lib.file.mkOutOfStoreSymlink "${configRoot}/fireaxe-addonroot.json";
  };
}
