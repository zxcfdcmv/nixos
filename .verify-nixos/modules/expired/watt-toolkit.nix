{ pkgs, config, userSettings, ... }:

let
  watt-version = "3.1.0";

  watt-src = pkgs.fetchurl {
    url = "${userSettings.githubProxy}/https://github.com/BeyondDimension/SteamTools/releases/download/${watt-version}/Steam++_v${watt-version}_linux_x64.tgz";
    hash = "sha256-+5m81PpqxkkihwD5CIGf4ZoWzCmoZq1D0oc+UEpBeD8=";
  };

  nss-bin = "${pkgs.nss}/bin";

  watt-toolkit = pkgs.stdenv.mkDerivation {
    pname = "watt-toolkit";
    version = watt-version;

    src = watt-src;

    nativeBuildInputs = with pkgs; [
      makeWrapper
    ];

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/bin
      mkdir -p $out/share/watt-toolkit

      cp -r * $out/share/watt-toolkit/

      chmod +x $out/share/watt-toolkit/Steam++.sh

      cat > $out/bin/watt-toolkit-launcher <<'EOF'
      #!/usr/bin/env bash
      set -e

      NIX_SHARE="@out@/share/watt-toolkit"
      USER_SHARE="$HOME/.local/share/watt-toolkit"
      VERSION_FILE="$USER_SHARE/.nix-version"

      if [[ ! -f "$VERSION_FILE" ]] || [[ "$(cat "$VERSION_FILE")" != "@version@" ]]; then
        rm -rf "$USER_SHARE"
        mkdir -p "$USER_SHARE"
        cp -r "$NIX_SHARE/"* "$USER_SHARE/"
        echo "@version@" > "$VERSION_FILE"
      fi

      rm -f "$USER_SHARE/Steam++"

      # patch environment_check.sh，使用绝对路径调用 certutil
      if [[ -f "$USER_SHARE/script/environment_check.sh" ]]; then
        sed -i 's|command -v certutil|command -v ${nss-bin}/certutil|g' "$USER_SHARE/script/environment_check.sh"
        sed -i 's|certutil -d|${nss-bin}/certutil -d|g' "$USER_SHARE/script/environment_check.sh"
      fi

      # 预初始化 nssdb，避免脚本调用
      if [[ ! -d "$HOME/.pki/nssdb" ]]; then
        mkdir -p "$HOME/.pki/nssdb"
        chmod 700 "$HOME/.pki/nssdb"
        ${nss-bin}/certutil -d "$HOME/.pki/nssdb" -N --empty-password 2>/dev/null || true
      fi

      cd "$USER_SHARE"
      exec ${pkgs.steam-run}/bin/steam-run "$USER_SHARE/Steam++.sh" "$@"
      EOF

      substituteInPlace $out/bin/watt-toolkit-launcher \
        --replace '@out@' "$out" \
        --replace '@version@' "${watt-version}"

      chmod +x $out/bin/watt-toolkit-launcher

      makeWrapper $out/bin/watt-toolkit-launcher $out/bin/watt-toolkit \
        --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath (with pkgs; [ libice libsm libx11 libxcb libxkbcommon libxcursor libxi libxrandr libxext libxfixes libxcomposite libxdamage libxinerama libxrender fontconfig freetype glib openssl zlib icu mesa libglvnd stdenv.cc.cc.lib ])}"
    '';

    meta = {
      description = "开源跨平台的多功能 Steam 游戏工具箱";
      homepage = "https://steampp.net/";
      license = pkgs.lib.licenses.gpl3;
      platforms = [ "x86_64-linux" ];
    };
  };

in {
  home = {
    packages = [ watt-toolkit ];
  };
}
