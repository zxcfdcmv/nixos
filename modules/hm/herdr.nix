# modules/hm/herdr.nix
{ config, pkgs, ... }:
{
  programs.herdr = {
    enable = true;
    settings = {
      theme = {
        name = "terminal";
      };
      onboarding = false;

      ui = {
        confirm_close = false;
        prompt_new_tab_name = false;
        toast.clipboard.enabled = false;
        sound.enabled = false;
        sidebar_width = 20;
      };
    };   
  };

  home.packages = [
    (pkgs.writeShellScriptBin "herdr-ai" ''
      exec ${pkgs.foot}/bin/footclient \
        --app-id=herdr-ai \
        -e herdr "$@"
    '')
  ];
}
