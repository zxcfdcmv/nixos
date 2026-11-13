# NixOS Flake 配置

> 个人 NixOS 桌面环境的声明式配置，支持多主机复用与模块化维护。

## 系统使用

| 层级 | 工具选型 |
|------|---------|
| linux内核 | CachyOS |
| 系统管理 | Nix Flakes + Home Manager |
| 显示协议 | Wayland + x11 |
| 合成器/窗口管理 | driftwm (Wayland) / vxwm (x11) |
| 代理工具 | dae |
| 邮箱客户端 | rbw + aerc |
| 编辑 | helix / Zed |
| 输入法 | fcitx5 (小鹤音形) |

## 特点

- **模块化架构**：系统配置按功能拆分（硬件、网络、桌面环境、用户配置），通过 `imports` 组合复用
- **声明式管理**：完整系统状态版本化，环境重建可 100% 复现
- **一键切换显示协议**：支持根据`tty`一键切换`Wayland(river+kwm)`/`x11(vxwm)`环境
- **Steam配置**: 使用nix工具声明式配置Steam
- **Nix化管理**: Nix化管理 drg的`mint`、l4d2的配置/`fireaxe`、tf2的配置/mod、CDDA
- **邮箱客户端**: 使用`rbw+aerc`，换环境也可直接查看邮件

## 快速开始

```bash
# 日常更新
sudo nixos-rebuild switch --flake .#nixos
```

## 换电脑

磁盘布局声明在 `modules/disko.nix`，装机不用手动分区。两种方式任选：

- **单机直装（推荐）**：新机器 U 盘启动，直接从 GitHub 拉配置装
- **双机远程**：新机器不方便接显示器时，从旧机器用 `nixos-anywhere` 装

前置条件：有线网（无线用 `nmtui`）、UEFI 启动。

### 装之前先加密码

配置里没有用户密码也没开 sshd，装完会登录不进去。先在 `modules/nixos/default.nix` 加一行：

```nix
users.users.zxcfdcmv.initialPassword = "nixos";
```

装完立刻 `passwd` 改掉。单机路线改的是 `/tmp` 副本，重启即失效；远程路线改的是自己的仓库，记得删掉并提交。

### 单机直装

```bash
# 1. 安装器里联网并配缓存（ISO 有自己的 nix.conf，不读 flake 里的 substituters）
sudo -i
nmtui
tee -a /etc/nix/nix.conf <<'EOF'
extra-substituters = https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://attic.xuyh0120.win/lantian https://deepseek-harness-nix.cachix.org
extra-trusted-public-keys = lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc= deepseek-harness-nix.cachix.org-1:5NrkwLN9veNMhiINtU5ZeV4isXFhFsOwn6Ms7J1M+TA=
EOF
systemctl restart nix-daemon

# 2. 拉配置（/tmp 是内存盘，重启就没了）
git clone https://github.com/zxcfdcmv/nixos /tmp/nixos && cd /tmp/nixos

# 3. 生成这台机器的硬件配置（--no-filesystems 不能省，否则和 disko.nix 冲突）
nixos-generate-config --no-filesystems --root /tmp/gen
cp /tmp/gen/etc/nixos/hardware-configuration.nix .

# 4. 分区 + 安装 + 写启动项
nix run 'github:nix-community/disko/latest#disko-install' -- \
  --write-efi-boot-entries --flake .#nixos --disk main /dev/nvme0n1
```

`--disk` 按盘型替换：NVMe 用 `/dev/nvme0n1`，SATA 用 `/dev/sda`，虚拟机用 `/dev/vda`。不加 `--write-efi-boot-entries` 只写 EFI 分区、不动 NVRAM。

这一步不只是格式化：分区几秒，然后会求值整套配置、下载/构建全部软件，最后拷进 `/mnt/nix/store`。系统闭包约 **23 GiB**，慢是正常的；装完首次开机不用再下载。加 `-L` 看实时日志。

重启后改密码，并重新拉一份配置到主目录（`/tmp` 的副本已随重启消失）：

```bash
passwd
git clone https://github.com/zxcfdcmv/nixos ~/nixos && cd ~/nixos
sudo nixos-generate-config --no-filesystems --root /tmp/gen
cp /tmp/gen/etc/nixos/hardware-configuration.nix .
sudo nixos-rebuild switch --flake .#nixos
```

### 双机远程

新机器安装器里 `passwd root`，旧机器确认 `ssh root@<IP>` 能进，然后：

```bash
# 可选：先开虚拟机试跑
nix run github:nix-community/nixos-anywhere -- --vm-test --flake .#nixos --disk main /dev/vda

# 生成硬件配置并安装（阶段：kexec → disko → install → reboot）
nix run github:nix-community/nixos-anywhere -- \
  --flake .#nixos --disk main /dev/nvme0n1 \
  --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
  root@<IP>
```

失败可以只重跑部分阶段：`--phases disko,install`。

### 换机器后还要看

- `hardware-configuration.nix` 的 `kvm-amd` / `kvm-intel` 和 `hardware.cpu.amd.updateMicrocode`
- `modules/nixos/amd_nvidia.nix` 是 AMD + NVIDIA 专用，纯 Intel 核显要注释掉
- `hostName` 固定为 `nixos`，整个 flake 只输出一个 `nixosConfigurations.nixos`；新旧两台同时用需要拆成 `hosts/`
- `flake.lock` 在 `.gitignore` 里，新机器会重新解析依赖
- `disko-install` / `disko` / `nixos-anywhere` 都会**清空目标磁盘**，回车前确认设备名
