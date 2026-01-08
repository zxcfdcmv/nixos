无桌面环境，使用显示管理器greetd的tuigreet+窗口管理器niri

# 一键安装
1.  Live ISO 启动 → 分区挂载到 `/mnt`
2.  `sudo nixos-generate-config --root /mnt`
3.  `sudo git clone https://github.com/YOUR_NAME/my-nixos-config /mnt/etc/nixos`
4.  核对 `/mnt/etc/nixos/hardware-configuration.nix` 中的 UUID、内核参数
5.  `sudo nixos-install --flake /mnt/etc/nixos#hostname`
6.  重启进入系统

# 配置上传至github(重头开始)
1. 移动配置至普通用户目录, 并配置权限
> 如果使用了`flakes`, 则修改后无需关注`/etc/nixos`目录, 就可以在任何地方重建系统，没有了权限问题, 命令如下(其中最后的字段为`配置所在位置`以及`hostname`):
> `sudo nixos-rebuild switch --flake ~/nixos#nixos`
  ```bash
    sudo mkdir -p ~/nixos/
    sudo mv /etc/nixos/* ~/nixos
    sudo chown -R $USER:users ~/nixos
  ```

1. 初始化git仓库, 并添加配置文件
  ```bash
    cd ~/nixos
    git init
    git add .
    git commit -m "init NixOS configuration"
  ```
1. 创建一个新的github空仓库, 无需初始化`README`和`.gitignore`
1. 添加公钥到github
  ```
    ssh-keygen -t ed25519 -C "your_email@example.com"
    cat ~/.ssh/id_ed25519.pub
  ```
  然后打开 GitHub → Settings → SSH and GPG keys → New SSH key → 粘贴进去
1. 将本地仓库推送到github
  ```bash
    git remote add origin git@github.com:username/nixos.git
    git branch -M main
    git push origin main
  ```
