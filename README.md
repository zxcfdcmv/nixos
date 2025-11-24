# my-nixos-config

个人 NixOS 配置（flake + home-manager + niri）。

## 一键安装
1.  Live ISO 启动 → 分区挂载到 `/mnt`
2.  `sudo nixos-generate-config --root /mnt`
3.  `sudo git clone https://github.com/YOUR_NAME/my-nixos-config /mnt/etc/nixos`
4.  核对 `/mnt/etc/nixos/hardware-configuration.nix` 中的 UUID、内核参数
5.  `sudo nixos-install --flake /mnt/etc/nixos#hostname`
6.  重启进入系统
