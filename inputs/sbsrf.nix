{ config, lib, pkgs, ... }:
let
  src = pkgs.fetchFromGitHub {
    owner  = "sbsrf";          # 举例：声笔
    repo   = "sbsrf";
    rev    = "main";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # nix-prefetch-url 算
  };
  schemaDir = "${src}/sbxlm";
in
{
  xdg = {
    dataFile = {
      "fcitx5/rime/sbxlm".source = schemaDir;
    };
    configFile."fcitx5/rime/default.custom.yaml".text = ''
      patch:
        schema_list:
          - schema: sbfd          # 声笔自然码
          - schema: sbfm
          - schema: sbmm
        switcher/hotkeys: false
        ascii_composer/good_old_caps_lock: true
        ascii_composer/switch_key:
          Caps_Lock: noop
          Shift_L: commit_code
          Shift_R: commit_code
    '';
  };
}
