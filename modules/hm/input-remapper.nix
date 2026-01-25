{ config, pkgs, ... }:
{
  xdg.configFile."input-remapper-2/presets/E-Signal USB Gaming Mouse/PZ-quick-attack.json".text = ''
    [
        {
            "input_combination": [
                {
                    "type": 1,
                    "code": 275,
                    "origin_hash": "2354d7a02d62de000476614c0ba445a2"
                }
            ],
            "target_uinput": "keyboard + mouse",
            "output_symbol": "key_down(BTN_RIGHT).\nkey_down(BTN_LEFT).\nhold(key_down(v).wait(10).key_up(v).wait(50)).\nkey_up(BTN_LEFT).\nkey_up(BTN_RIGHT)",
            "mapping_type": "key_macro"
        }
    ]
  '';
}
