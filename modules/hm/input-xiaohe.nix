{ config, lib, pkgs, ... }:
let
  flypy-src = pkgs.fetchFromGitHub {
    owner  = "jqtmviyu";
    repo   = "flypy";
    rev    = "main";
    sha256 = "sha256-GKB9lqV1uJCpCgDzFbchHYO2kW6mV8Sq2kBy0bropXQ=";
  };
in
{
  xdg.dataFile = {
    "fcitx5/rime/flypy.schema.yaml".source = "${flypy-src}/flypy.schema.yaml";
    "fcitx5/rime/flypy.dict.yaml".source = "${flypy-src}/flypy.dict.yaml";
    "fcitx5/rime/flypy".source = "${flypy-src}/flypy";      
    "fcitx5/rime/lua".source = "${flypy-src}/lua";      
    "fcitx5/rime/flypydz.schema.yaml".source = "${flypy-src}/flypydz.schema.yaml";      
    "fcitx5/rime/flypydz.dict.yaml".source = "${flypy-src}/flypydz.dict.yaml";      
    "fcitx5/rime/default.custom.yaml".text = ''
      patch:
        schema_list:
          - schema: flypy # 添加小鹤音形
        switcher/hotkeys: false # 定製喚出方案選單的快捷鍵, 默认是ctrl + `或者f4

        ascii_composer/good_old_caps_lock: true
        ascii_composer/switch_key:
          Caps_Lock: noop
          Shift_L: commit_code
          Shift_R: noop
          Control_L: noop
          Control_R: noop

        key_binder/bindings:
          - when: paging
            accept: bracketleft
            send: Page_Up
          - when: has_menu
            accept: bracketright
            send: Page_Down
          - when: always
            accept: "Shift+space"
            send: "Shift+space"
    '';
  };
}
