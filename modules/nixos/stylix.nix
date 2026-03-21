{ pkgs, stylix, ... }:
{
  imports = [
    stylix.nixosModules.stylix
  ];

  stylix = {
    enable = true;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/ayu-dark.yaml";
    image = ../../assets/pictures/lu.jpg;

    # 设置系统字体
    fonts = {
      serif = {
        package = pkgs.maple-mono.NF-CN;
        name = "Maple Mono NF CN";
      };
      sansSerif = {
        package = pkgs.maple-mono.NF-CN;
        name = "Maple Mono NF CN";
      };
      monospace = {
        package = pkgs.maple-mono.NF-CN;
        name = "Maple Mono NF CN";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };

      sizes = {
        applications = 14;
        desktop = 14;
        terminal = 16;
        popups = 14;
      };
    };

    opacity = {
      applications = 0.8;  # 普通应用窗口
      desktop = 0.8;       # 桌面背景/面板
      terminal = 0.8;      # 终端
      popups = 0.8;        # 弹窗、工具提示
    };    

    autoEnable = true;
  };
}
