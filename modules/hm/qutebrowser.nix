{ pkgs, ... }: {
  programs.qutebrowser = {
    enable = true;
    extraConfig = ''
      # 搜索引擎
      c.url.searchengines = {
        "DEFAULT": "https://cn.bing.com/search?q={}",
        "g": "https://www.google.com/search?q={}",
      }

      c.completion.open_categories = ["searchengines", "bookmarks", "history"]

      c.url.start_pages = ["about:blank"]
      c.fonts.default_family = "Maple Mono NF CN"
      c.tabs.position = "left"
      c.tabs.width = "8%"

      # 隐私与安全
      c.content.webgl = False
      c.content.canvas_reading = False
      c.content.headers.user_agent = "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0"
      c.content.cookies.accept = "no-3rdparty"
      c.content.headers.do_not_track = True      
    '';
  };

  xdg.configFile."qutebrowser/quickmarks".text = ''
    github https://github.com
  '';
}
