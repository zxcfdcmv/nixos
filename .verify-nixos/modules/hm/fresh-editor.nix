# modules/hm/fresh-editor.nix
# fresh（上游 sinelaw/fresh）：终端里的全屏文本编辑器。
# nixpkgs 已收录（pkgs.by-name/fr/fresh-editor），无需额外 flake input；
# 包里已经 wrap 了 --no-upgrade-check，并把 python3 放进 PATH 供插件用。
{ pkgs, ... }:
{
  home.packages = [ pkgs.fresh-editor ];

  # 想让它当默认编辑器的话，取消下面两行注释（默认仍是 modules/nixos/default.nix 里的 hx）：
  # home.sessionVariables.EDITOR = "fresh";
  # home.sessionVariables.VISUAL = "fresh";
}
