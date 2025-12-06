{ config, lib, pkgs, sbsrf-plum, ... }:
let
  linkScript = pkgs.writeScript "link-sbxlm" ''
    #!${pkgs.bash}/bin/bash
    ${builtins.readFile ../scripts/link-sbxlm.sh}
  '';
in
{
  home = {
    file.".local/share/fcitx5/rime/.keep".text = "";
    activation = {
      linkSbxlm = lib.hm.dag.entryBefore ["linkGeneration"] ''
        echo "Linking sbxlm files ..."
        ${linkScript} ${sbsrf-plum}/sbxlm "$HOME/.local/share/fcitx5/rime"
      '';
    };
  };

  xdg = {
    dataFile."fcitx5/rime/default.custom.yaml" = {
      text = ''
        patch:
          schema_list:
            - schema: sbfd
            - schema: sbfm
            - schema: sbmm
        switcher:
          abbreviate_options: true
          caption: "〔方案选单〕"
          fold_options: true
          option_list_separator: '／'
          hotkeys:
            # - "Control+grave"
            # - "Control+Shift+grave"
            - F4
        ascii_composer:
          good_old_caps_lock: true
          switch_key:
            Shift_L: commit_code
            Shift_R: noop
            Control_L: commit_code
            Control_R: noop
            Caps_Lock: clear
            Eisu_toggle: clear
      '';
      force = true;
    };
  };
}
