{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  pname = "watt-toolkit";
  version = "3.1.0"; # 请根据 GitHub Release 自行更改最新版本

  src = pkgs.fetchurl {
    url = "https://github.com{version}/Steam++_v${version}_linux_x64.tgz";
    # 首次构建如果 hash 报错，请将下面的 hash 替换为报错信息里提示的正确的 hash
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; 
  };

  # 声明运行时需要的依赖
  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = with pkgs; [
    stdenv.cc.cc.lib
    fontconfig
    xorg.libX11
    xorg.libICE
    xorg.libSM
    glib
    openssl
    zlib
  ];

  # 解压并将其放置到 Nix Store 指定目录
  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/watt-toolkit
    
    cp -r * $out/share/watt-toolkit/
    
    # 创建可执行文件软链接，并包装环境变量
    makeWrapper $out/share/watt-toolkit/WattToolkit $out/bin/watt-toolkit \
      --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath buildInputs}"
  '';

  meta = {
    description = "开源跨平台的多功能 Steam 游戏工具箱";
    homepage = "https://steampp.net/";
    license = pkgs.lib.licenses.gpl3;
    platforms = [ "x86_64-linux" ];
  };
}
