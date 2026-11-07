{ pkgs, ... }: {
  programs.qutebrowser = {
    enable = true;

    searchEngines = {
      DEFAULT = "https://cn.bing.com/search?q={}";
      g = "https://www.google.com/search?q={}";
      gh = "https://github.com/search?q={}";
    };      
    settings = {
      url.start_pages = ["qute://start/"];

      tabs = {
        position = "left";
        width = "8%";
      };
      content = {
        autoplay = false;
        javascript = {
          enabled = true;
          clipboard = "access";         
        };
        webgl = false;
        canvas_reading = true;
        headers = {
          do_not_track = false;
        };
        cookies.accept = "no-3rdparty";
        blocking = {
          enabled = true;
          method = "both";
          hosts.lists = [
            "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
          ];
          adblock.lists = [
            "https://easylist.to/easylist/easylist.txt"
            "https://easylist.to/easylist/easyprivacy.txt"
            "https://easylist-downloads.adblockplus.org/easylistchina.txt"
          ];
        };
      };
    };

    greasemonkey = [
      (pkgs.writeText "github-redirect.user.js" ''
        // ==UserScript==
        // @name         GitHub to bgithub Redirect
        // @match        https://github.com/*
        // @match        https://gist.github.com/*
        // @run-at       document-start
        // ==/UserScript==
        
        (function() {
            'use strict';
            const newHost = 'bgithub.xyz';
            if (window.location.hostname !== newHost) {
                window.location.replace(
                    window.location.href.replace(window.location.hostname, newHost)
                );
            }
        })();
      '')
    ];
  };

  xdg.configFile."qutebrowser/quickmarks".text = ''
    github https://github.com
  '';

  # xdg.configFile."qutebrowser/bookmarks/urls".text = ''
  # '';
}
