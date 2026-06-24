# NixOS Flake 配置

&gt; 个人 NixOS 桌面环境的声明式配置，支持多主机复用与模块化维护。

## 技术栈

| 层级 | 技术选型 |
|------|---------|
| 系统管理 | Nix Flakes + Home Manager |
| 显示协议 | Wayland |
| 合成器 | river (Wayland compositor) |
| 窗口管理 | kwm |
| linux内核 | CachyOS |
| 代理工具 | dae |
| 邮箱客户端 | rbw + aerc |

## 设计特点

- **模块化架构**：系统配置按功能拆分（硬件、网络、桌面环境、用户配置），通过 `imports` 组合复用
- **声明式管理**：完整系统状态版本化，环境重建可 100% 复现
- **Wayland 原生**：从登录管理器到合成器全链路 Wayland，无 X11 依赖
- **Steam配置**: 使用nix工具声明式配置Steam
- **Nix化多个mod管理器**: Nix化 drg的`mint` + l4d2的`fireaxe`
- **邮箱客户端**: 使用rbw+aerc，换环境也可直接查看邮件

## 快速开始

```bash
# 日常更新
sudo nixos-rebuild switch --flake .#nixos
```
