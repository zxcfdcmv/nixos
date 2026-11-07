# modules/hm/fresh-editor.nix
# fresh（上游 sinelaw/fresh）：终端里的全屏文本编辑器。
# Home Manager 自带 programs.fresh-editor，不需要手动 home.packages。
{ pkgs, ... }:
{
  programs.fresh-editor = {
    enable = true;

    mutableSettings = true;

    settings = {
      version = 1;
      theme = "terminal"; # 跟随终端调色板
      locale = "zh-CN"; # 中文界面
      editor = {
        tab_size = 2;
        animations = false;
        line_numbers = true;
        auto_indent = true;
        syntax_highlighting = true;
        show_tilde = false;
      };
      
      terminal = {
        jump_to_end_on_output = false;
      };
      
      file_explorer = {
        width = "20%";
      };
      
      plugins = {
        orchestrator.settings.autoOpenDock = "never";
        welcome_screen.settings.showOnStartup = false;
      };
      open_last_workspace = true;
    };

    # 想让它当默认编辑器就打开：
    # defaultEditor = true;
  };
  home.packages = [
    (pkgs.writeShellScriptBin "fresh-ai" ''
      exec ${pkgs.foot}/bin/footclient \
        --app-id=fresh-ai \
        -e fresh "$@"
    '')
  ];
}
