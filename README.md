# NixOS Flake 配置

&gt; 个人 NixOS 桌面环境的声明式配置，支持多主机复用与模块化维护。

## 系统使用

| 层级 | 工具选型 |
|------|---------|
| linux内核 | CachyOS |
| 系统管理 | Nix Flakes + Home Manager |
| 显示协议 | Wayland + x11 |
| 合成器 | river (Wayland compositor) |
| 窗口管理 | kwm (Wayland) / vxwm (x11) |
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
