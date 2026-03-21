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
        javascript.clipboard = "access";
        webgl = false;
        canvas_reading = false;
        headers = {
          do_not_track = true;
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
  };

  xdg.configFile."qutebrowser/quickmarks".text = ''
    github https://github.com
  '';

  # xdg.configFile."qutebrowser/bookmarks/urls".text = ''
  # '';
}
