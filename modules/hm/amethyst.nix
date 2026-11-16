# modules/hm/amethyst.nix
# Amethyst Mod Manager —— Linux 原生 Qt/Mod Organizer 风格 mod 管理器。
# 上游自带 flake（python313 + PySide6 + libloot + native/amethyst_filegraph 的 Rust 部分），
# 这里只做引用，版本跟着 flake.lock 走；更新用 `nix flake update amethyst`。
{ pkgs, inputs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  amethyst = inputs.amethyst.packages.${system}.default;

  # NixOS 上 Amethyst 用 steam-run 包 Proton，而 steam-run 的 LD_LIBRARY_PATH
  # 只有 nix store 路径；它自动注入的 gameoverlayrenderer.so 没有 RPATH、要找
  # /usr/lib/libGL.so.1，于是 exec bash 直接 exit 127、游戏起不来。
  # 关掉自动覆盖层（Steam 自己启动游戏时仍带覆盖层，不受影响）。
  # 直接写进 wrapper，避免依赖桌面会话有没有 source 到 hm 的环境变量。
  amethyst-wrapped = pkgs.symlinkJoin {
    name = "amethyst-mod-manager-wrapped";
    paths = [ amethyst ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/amethyst-mod-manager"
      makeWrapper ${amethyst}/bin/amethyst-mod-manager "$out/bin/amethyst-mod-manager" \
        --set AMM_STEAM_OVERLAY 0
    '';
  };
in
{
  home.packages = [ amethyst-wrapped ];
}
