# modules/hm/obsidian.nix
{ config, pkgs, lib, userSettings, ... }:
{
  programs.obsidian = {
    enable = true;
    vaults.notes.target = "Documents/Obsidian";

    defaultSettings = {
      app = {
        showUnsupportedFiles = true;
        alwaysUpdateLinks = true;
        # spellcheck = true;
        tabSize = 2;
        useTab = false;
        # defaultViewMode = "source"; # 编辑模式
        defaultViewMode = "preview"; # 阅读模式
        livePreview = false; # 源码模式
      };
      appearance.theme = "system";
      themes = with pkgs.obsidianThemes; [
        # obsidian-gruvbox
        minimal
      ];
      communityPlugins = with pkgs.obsidianPlugins; [
      # 查看有哪些插件
      # nix eval --json github:karaolidis/nix-obsidian-extensions#legacyPackages.x86_64-linux.obsidianPlugins --apply builtins.attrNames | jq -r '.[]' &> ~/obsidian_plugins.txt
        {
          pkg = obsidian-git;
          settings = {
            autoSaveInterval = 10;
            autoPush = true;
            commitMessage = "vault backup: {{date}}";
          };
        }
        dataview
        dataview-serializer
        notepix
      ];
    }; 
  };
}
