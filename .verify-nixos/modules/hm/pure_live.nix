# modules/hm/pure_live.nix
{ pkgs, lib, ... }:

let
  pure-live = pkgs.stdenv.mkDerivation rec {
    pname = "pure-live";
    version = "3.1.19-4108";

    src = pkgs.fetchurl {
      url = "https://github.com/liuchuancong/pure_live/releases/download/v3.1.19/PureLive-3.1.19-4108-linux-x64.tar.gz";
      hash = "sha256-i2S28YaS9Sh6i7iprGj7eYqfODcooKEo9TiSyuzpdPk=";
    };

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      makeWrapper
    ];

    # 这里的依赖只给外壳界面用，保持原生 NVIDIA/Wayland 流畅不卡顿
    buildInputs = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      glib
      gtk3
      cairo
      pango
      harfbuzz
      atk
      gdk-pixbuf
      libepoxy
      libx11
      libxkbcommon
      wayland
      
      # 必须把系统 mpv 塞进来，提供真正干净的运行时 libmpv 依赖
      mpv
      libpulseaudio
      alsa-lib
    ];

    # 让构建直接通过，不在未使用的可选二进制上纠结
    autoPatchelfIgnoreMissingDeps = [
      "libjvm.so"
      "libxml2.so.2"
    ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/opt/pure-live" "$out/bin"
      cp -r . "$out/opt/pure-live/"
      chmod +x "$out/opt/pure-live/pure_live"

      # ================= 【核心黑科技】 =================
      # 物理删除上游包里自带的、导致符号查找错误和初始化黑屏的坏库
      rm -f "$out/opt/pure-live/lib/libmpv.so"*
      rm -rf "$out/opt/pure-live/lib/fallback"
      # =================================================

      # 包装启动命令：强制注入系统里健康的 mpv 和音频依赖库路径
      makeWrapper "$out/opt/pure-live/pure_live" "$out/bin/pure-live" \
        --run "cd '$out/opt/pure-live'" \
        --prefix PATH : "${pkgs.xdg-user-dirs}/bin" \
        --set LD_LIBRARY_PATH "${lib.makeLibraryPath [
          pkgs.mpv
          pkgs.libpulseaudio
          pkgs.alsa-lib
          pkgs.libGL
          pkgs.mesa
        ]}:$out/opt/pure-live/lib"

      runHook postInstall
    '';

    # 仅让 auto-patchelf 修复剩余的 Flutter 核心界面插件
    preFixup = ''
      addAutoPatchelfSearchPath "$out/opt/pure-live/lib"
    '';

    meta = with lib; {
      description = "Pure Live streaming client";
      homepage = "https://github.com";
      platforms = [ "x86_64-linux" ];
      mainProgram = "pure-live";
    };
  };
in
{
  home.packages = [ pure-live ];
}
