{ config, pkgs, userSettings, sops-nix, ... }:

let
  runtimeDir = "/run/user/1000"; 
in
{
  imports = [
    sops-nix.homeManagerModules.sops 
    ./rbw-sops.nix
  ];

  bitwardenSops = {
    enable = true;
    keyName = "sops-age-key";
  };

  sops = {
    age.keyFile = "${runtimeDir}/sops-age-key";
    defaultSopsFile = ../../assets/secrets.yml;
    secrets = {
      "email/gmail_password" = { };
      "email/outlook_password" = { };
      "email/foxmail_password" = { };
      "email/netease_password" = { };
    };
  };

  programs.aerc = {
    enable = true;

    extraConfig = {
      general = {
        unsafe-accounts-conf = true;
        editor = "hx";
        default-save-path = "${config.xdg.dataHome}/mail/attachments";
      };
      
      ui = {
        sidebar-width = 30;
        mouse-enabled = false;
        index-format = "%4C %Z %D %-17.17n %s";
        timestamp-format = "01-02 15:04";
      };
      
      filters = {
        "text/plain" = "colorize";
        "text/html" = "${pkgs.w3m}/bin/w3m -T text/html -dump";
      };
    };
  };

  accounts.email.accounts = {
    # ========== Gmail ==========
    gmail = {
      address = "${userSettings.username}@gmail.com";
      userName = "${userSettings.username}@gmail.com";
      realName = userSettings.username;
      
      aerc = {
        enable = true;
        extraAccounts = {
          source = "imaps://${userSettings.username}%40gmail.com@imap.gmail.com:993";
          source-cred-cmd = "cat ${config.sops.secrets."email/gmail_password".path}";
          
          outgoing = "smtps+plain://${userSettings.username}%40gmail.com@smtp.gmail.com:465";
          outgoing-cred-cmd = "cat ${config.sops.secrets."email/gmail_password".path}";
          
          folders-inbox = "INBOX";
          folders-sent = "[Gmail]/Sent Mail";
          folders-trash = "[Gmail]/Trash";
          folders-draft = "[Gmail]/Drafts";
          folders-archive = "[Gmail]/All Mail";          

          default = "INBOX";
          signature-cmd = "echo '-- ${userSettings.username}'";
        };
      };
    };

    # ========== Outlook ==========
    outlook = {
      address = "${userSettings.username}@outlook.com";
      userName = "${userSettings.username}@outlook.com";
      realName = userSettings.username;
      
      aerc = {
        enable = true;
        extraAccounts = {
          source = "imaps://${userSettings.username}%40outlook.com@outlook.office365.com:993";
          source-cred-cmd = "cat ${config.sops.secrets."email/outlook_password".path}";
          
          outgoing = "smtps+plain://${userSettings.username}%40outlook.com@smtp.office365.com:587";
          outgoing-cred-cmd = "cat ${config.sops.secrets."email/outlook_password".path}";

          folders-inbox = "INBOX";
          folders-sent = "Sent";
          folders-trash = "Deleted";
          folders-draft = "Drafts";
          folders-archive = "Archive";         
          
          default = "INBOX";
          signature-cmd = "echo '-- ${userSettings.username}'";
        };
      };
    };

    # ========== Foxmail (QQ邮箱) ==========
    foxmail = {
      address = userSettings.email;
      userName = userSettings.email;
      realName = userSettings.username;
      primary = true;
      aerc = {
        enable = true;
        extraAccounts = {
          source = "imaps://${userSettings.username}%40foxmail.com@imap.qq.com:993";
          source-cred-cmd = "cat ${config.sops.secrets."email/foxmail_password".path}";
          
          outgoing = "smtps+plain://${userSettings.username}%40foxmail.com@smtp.qq.com:465";
          outgoing-cred-cmd = "cat ${config.sops.secrets."email/foxmail_password".path}";

          folders-inbox = "INBOX";
          folders-sent = "Sent Messages";
          folders-trash = "Deleted Messages";
          folders-draft = "Drafts";         

          default = "INBOX";
          signature-cmd = "echo '-- ${userSettings.username}'";
        };
      };
    };

    # ========== 163 邮箱 ==========
    netease = {
      address = "${userSettings.username}@163.com";
      userName = "${userSettings.username}@163.com";
      realName = userSettings.username;
      
      aerc = {
        enable = true;
        extraAccounts = {
          source = "imaps://${userSettings.username}%40163.com@imap.163.com:993";
          source-cred-cmd = "cat ${config.sops.secrets."email/netease_password".path}";
          
          # 163 SMTP 端口 465 或 994
          outgoing = "smtps+plain://${userSettings.username}%40163.com@smtp.163.com:465";
          outgoing-cred-cmd = "cat ${config.sops.secrets."email/netease_password".path}";
          
          folders-inbox = "INBOX";
          folders-sent = "Sent Messages";
          folders-trash = "Deleted Messages";
          folders-draft = "Drafts";          

          default = "INBOX";
          signature-cmd = "echo '-- ${userSettings.username}'";
        };
      };
    };
  };
}
