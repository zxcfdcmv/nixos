# modules/nixos/helium.nix
{ config, pkgs, lib, helium, ... }:
{
  imports = [
    helium.nixosModules.default
  ];

  programs.helium = {
    enable = true;   

    flags = [
      "--ozone-platform-hint=auto"
    ];

    policies = {
      "ExtensionInstallForcelist" = [
        # Bitwarden (使用微软商店 ID 和 微软 CRX 更新源)
        "jbkfoedgocfjonbeabaeeioedeocecga;https://edge.microsoft.com/extensionwebstorebase/v1/crx"
        
        # 沉浸式翻译 (使用微软商店 ID 和 微软 CRX 更新源)
        "amnoiceffbpcgofieenmbgicholldbno;https://edge.microsoft.com/extensionwebstorebase/v1/crx"
      ];


      "BrowserSignin" = 0;                      # 禁用浏览器登录
      "PasswordManagerEnabled" = false;         # 禁用密码管理器
      "SyncDisabled" = true;                    # 禁用同步
      "HomepageLocation" = "chrome://newtab";         # 设置主页
      "DefaultSearchProviderEnabled" = true;
      "DefaultSearchProviderSearchURL" = "https://cn.bing.com/search?q={searchTerms}"; 

      "ManagedSearchProviderSettings" = [
        {
          "keyword" = "g";                       
          "name" = "Google";
          "search_url" = "https://google.com/search?q={searchTerms}";
        }
        {
          "keyword" = "gai";                       
          "name" = "GoogleAI";
          "search_url" = "https://google.com/search?q={searchTerms}&udm=50";
        }
        {
          "keyword" = "n";                       
          "name" = "NixOS";
          "search_url" = "https://search.nixos.org/?q={searchTerms}";
        }
        {
          "keyword" = "gh";                      
          "name" = "GitHub";
          "search_url" = "https://github.com/?q={searchTerms}";
        }
      ];

      "HardwareAccelerationModeEnabled" = true;  # 强行开启硬件加速
      "MemorySaverModeEnabled" = 1;              # 开启激进的“内存节省模式”，自动冻结后台闲置标签页
      "PrivacySandboxAdTopicsEnabled" = false;    # 强行关闭谷歌底层偷偷画用户画像的隐私沙盒广告追踪
    };
  };
}
