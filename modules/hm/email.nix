{ config, pkgs, userSettings, ... }:

{
  sops = {
    age.sshKeyPaths = [ "/home/${userSettings.username}/.ssh/id_ed25519" ];
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      "email/gmail_password" = { };
    };
  };

  programs.aerc = {
    enable = true;

    extraConfig = {
      general = {
        unsafe-accounts-conf = true;
        editor = "hx";
        default-save-path = "~/Downloads";
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
      realName = "${userSettings.username}";
      
      aerc = {
        enable = true;
        extraAccounts = {
          source = "imaps://${userSettings.username}%40gmail.com@imap.gmail.com:993";
          source-cred-cmd = "cat ${config.sops.secrets."email/gmail_password".path}";
          
          outgoing = "smtps+plain://${userSettings.username}%40gmail.com@smtp.gmail.com:465";
          outgoing-cred-cmd = "cat ${config.sops.secrets."email/gmail_password".path}";
          
          folders = {
            inbox = "INBOX";
            sent = "[Gmail]/Sent Mail";
            trash = "[Gmail]/Trash";
            draft = "[Gmail]/Drafts";
            archive = "[Gmail]/All Mail";
          };
          
          default = "INBOX";
          signature-cmd = "echo '-- \n${userSettings.username}'";
        };
      };
    };

    # ========== Outlook ==========
    outlook = {
      address = "${userSettings.username}@outlook.com";
      userName = "${userSettings.username}@outlook.com";
      realName = "${userSettings.username}";
      
      aerc = {
        enable = true;
        extraAccounts = {
          source = "imaps://${userSettings.username}%40outlook.com@outlook.office365.com:993";
          source-cred-cmd = "cat ${config.sops.secrets."email/outlook_password".path}";
          
          outgoing = "smtps+plain://${userSettings.username}%40outlook.com@smtp.office365.com:587";
          outgoing-cred-cmd = "cat ${config.sops.secrets."email/outlook_password".path}";
          
          folders = {
            inbox = "INBOX";
            sent = "Sent";
            trash = "Deleted";
            draft = "Drafts";
            archive = "Archive";
          };
          
          default = "INBOX";
          signature-cmd = "echo '-- \n${userSettings.username}'";
        };
      };
    };

    # ========== Foxmail (QQ邮箱) ==========
    foxmail = {
      address = "${userSettings.email}";
      userName = "${userSettings.email}";
      realName = "${userSettings.username}";
      
      aerc = {
        enable = true;
        extraAccounts = {
          # QQ邮箱服务器，用户名是 foxmail 地址
          source = "imaps://${userSettings.username}%40foxmail.com@imap.qq.com:993";
          source-cred-cmd = "cat ${config.sops.secrets."email/foxmail_password".path}";
          
          outgoing = "smtps+plain://${userSettings.username}%40foxmail.com@smtp.qq.com:465";
          outgoing-cred-cmd = "cat ${config.sops.secrets."email/foxmail_password".path}";
          
          folders = {
            inbox = "INBOX";
            sent = "Sent Messages";
            trash = "Deleted Messages";
            draft = "Drafts";
          };
          
          default = "INBOX";
          signature-cmd = "echo '-- \n${userSettings.username}'";
        };
      };
    };

    # ========== 163 邮箱 ==========
    netease = {
      address = "${userSettings.username}@163.com";
      userName = "${userSettings.username}@163.com";
      realName = "${userSettings.username}";
      
      aerc = {
        enable = true;
        extraAccounts = {
          source = "imaps://${userSettings.username}%40163.com@imap.163.com:993";
          source-cred-cmd = "cat ${config.sops.secrets."email/netease_password".path}";
          
          # 163 SMTP 端口 465 或 994
          outgoing = "smtps+plain://${userSettings.username}%40163.com@smtp.163.com:465";
          outgoing-cred-cmd = "cat ${config.sops.secrets."email/netease_password".path}";
          
          folders = {
            inbox = "INBOX";
            sent = "Sent Messages";
            trash = "Deleted Messages";
            draft = "Drafts";
          };
          
          default = "INBOX";
          signature-cmd = "echo '-- \n${userSettings.username}'";
        };
      };
    };
  };
}
