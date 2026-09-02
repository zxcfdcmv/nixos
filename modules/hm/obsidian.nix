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
        # {
        #   pkg = notepix;
        #   settings = {
        #     githubUsername = "${userSettings.username}";
        #     repositoryName = "notes";
        #     repositoryVisibility = "Public";  # 或 "Private"
        #     branchName = "images";
        #     folderPath = "assets/";
        #     deleteLocalFile = true;
        #     enableEncryption = true;
        #   };
        # }
        lazy-plugins
        {
          pkg = omnisearch;
          settings = {
            highlightMatches = true;
            ignoreDiacritics = true;
            showExcerpt = true;
            maxResults = 50;
    
            PDFIndexing = true;
            imagesIndexing = false;
            canvasIndexing = true;
    
            saveIndexToCache = true;
            refreshInterval = 30;
    
            HTTPserver = {
              enabled = false;
              port = 51361;
            };
          };
        }
      ];
    }; 
  };
}
