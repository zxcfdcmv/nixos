{ config, pkgs, lib, userSettings, ... }:
{
    home = {
        packages = with pkgs; [
            sublime4
            # (pkgs.symlinkJoin {
            #     name = "sublime4";
            #     paths = [ pkgs.sublime4 ];
            #     buildInputs = [ pkgs.makeWrapper ];
            #     postBuild = ''
            #         wrapProgram $out/bin/sublime_text \
            #         --prefix PATH: "${lib.makeBinPath [ pkgs.sublime-merge ]}"
            #     '';
            # })
            sublime-merge
        ];
    };
    
    xdg.configFile = {
        "sublime-text/Packages/User/Preferences.sublime-settings" = {
            source = config.lib.file.mkOutOfStoreSymlink "/home/${userSettings.username}/nixos/assets/sublime/preferences.sublime-settings";
        };
        "sublime-text/Packages/User/Package Control.sublime-settings" = {
            source = config.lib.file.mkOutOfStoreSymlink "/home/${userSettings.username}/nixos/assets/sublime/package_control.sublime-settings";
        };
    };
}
