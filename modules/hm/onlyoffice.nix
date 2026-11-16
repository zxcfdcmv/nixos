# modules/hm/onlyoffice.nix
{ config, pkgs, lib, inputs, userSettings, ... }:
{
  programs.onlyoffice = {
    enable = true;
    settings = {
      UITheme = "theme-system";
      editorWindowMode = false;
      ignoreMsgAboutOpenTabs = true;
      titlebar = "custom";
    };
  };

  home.activation = {
    copyFontsForOnlyoffice = lib.hm.dag.entryAfter ["writeBoundary"] ''
      TARGET_DIR="$HOME/.local/share/fonts/onlyoffice-real"
      mkdir -p "$TARGET_DIR"
      chmod -R u+w "$TARGET_DIR" 2>/dev/null || true
      [ -n "$TARGET_DIR" ] && rm -rf "$TARGET_DIR"/*

      cp -L ${pkgs.vista-fonts-chs}/share/fonts/truetype/* "$TARGET_DIR/" 2>/dev/null || true
      cp -L ${pkgs.maple-mono.NF-CN}/share/fonts/truetype/* "$TARGET_DIR/" 2>/dev/null || true
      cp -L ${pkgs.corefonts}/share/fonts/truetype/* "$TARGET_DIR/" 2>/dev/null || true
      cp -L ${pkgs.vista-fonts}/share/fonts/truetype/* "$TARGET_DIR/" 2>/dev/null || true
      cp -L ${pkgs.noto-fonts-color-emoji}/share/fonts/truetype/* "$TARGET_DIR/" 2>/dev/null || true

      find -L ${pkgs.noto-fonts-cjk-sans}/share/fonts/ -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp -f {} "$TARGET_DIR/" \; 2>/dev/null || true
      find -L ${pkgs.noto-fonts-cjk-serif}/share/fonts/ -type f \( -name "*.ttf" -o -name "*.ttc" -o -name "*.otf" \) -exec cp -f {} "$TARGET_DIR/" \; 2>/dev/null || true
    '';
  };
}
