{ config, pkgs, nix-flatpak, userSettings, ... }:
{
  imports = [
    nix-flatpak.nixosModules.nix-flatpak
  ];
  # Flatpak 必须系统启用
  services.flatpak.enable = true;

  home-manager.users.${userSettings.username} = {
    imports = [
      nix-flatpak.homeManagerModules.nix-flatpak
    ];

    services.flatpak = {
      enable = true;
      remotes = [
        {
          name = "flathub";
          location = "https://mirror.sjtu.edu.cn/flathub/flathub.flatpakrepo";
        }
      ];

      # 安装 Bottles
      packages = [
        "com.usebottles.bottles"
      ];

      # 权限（替代 Flatseal）
      overrides = {
        "com.usebottles.bottles" = {
          Context = {
            filesystems = [ "home" "xdg-download" ];
            sockets = [ "wayland" "x11" "pulseaudio" ];
            devices = [ "all" ];
          };
        };
      };
    };
  };
}
