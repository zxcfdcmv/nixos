# modules/hm/fresh-editor.nix
# fresh（上游 sinelaw/fresh）：终端里的全屏文本编辑器。
# Home Manager 自带 programs.fresh-editor，不需要手动 home.packages。
{ ... }:
{
  programs.fresh-editor = {
    enable = true;

    # 声明式设置写到 ~/.config/fresh/config_linux.json，
    # 同时保留 Fresh 自己的 ~/.config/fresh/config.json 可写，
    # 这样 Settings UI 仍能修改其他选项；同名 key 以声明的为准。
    mutableSettings = true;

    settings = {
      version = 1;
      theme = "terminal"; # 跟随终端调色板
      locale = "zh-CN"; # 中文界面
      editor.animations = false; # 关闭 UI 动画
      
      plugins = {
        orchestrator.settings.autoOpenDock = "never";
        welcome_screen.settings.showOnStartup = false;
      };
      open_last_workspace = true;
    };

    # 想让它当默认编辑器就打开：
    # defaultEditor = true;
  };
}
