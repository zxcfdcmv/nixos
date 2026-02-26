{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    rustc
    cargo
    rust-analyzer
    clippy
    rustfmt
    gcc
    pkg-config
    
    # 图形界面依赖
    libxcb
    libxkbcommon
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    xorg.libXext
    fontconfig
    freetype
    libGL
    vulkan-loader
  ];

  # 设置环境变量，确保链接器能找到库
  shellHook = ''
    export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [
      pkgs.xorg.libX11
      pkgs.xorg.libXcursor
      pkgs.xorg.libXrandr
      pkgs.xorg.libXi
      pkgs.vulkan-loader
    ]}:$LD_LIBRARY_PATH
  '';
}
