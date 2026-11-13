# 声明式磁盘布局：分区、格式化、子卷、挂载点全在这里定义。
# 因此 hardware-configuration.nix 里不再需要 UUID 形式的 fileSystems。
# 没有 swap 分区：swap 完全由 zram 提供（modules/nixos/optimize.nix）。
#
# 注意：`nixos-rebuild switch` 只会按这里*计算*出 /etc/fstab，不会重新分区或格式化。
# 真正抹盘只发生在显式执行 disko / nixos-anywhere 时，例如给新机器装机：
#
#   nix run github:nix-community/nixos-anywhere -- \
#     --flake .#nixos --disk main /dev/nvme0n1 root@<目标机IP>
#
# 其中 `--disk main /dev/xxx` 会覆盖下面的默认设备名，所以换机器不用改这个文件。
{ lib, ... }:
{
  disko.devices.disk.main = {
    type = "disk";
    # 仅作为默认值；装机时用 `--disk main /dev/sdX` 覆盖
    device = lib.mkDefault "/dev/nvme0n1";

    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          # 固定 PARTUUID：让生成的 /etc/fstab 用 by-partuuid，
          # 与这块盘现有的分区一一对应（换机器重装时也会写成同一个值）。
          uuid = "1c779e97-f991-4b1e-8995-2113cf25b38d";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "fmask=0022" "dmask=0022" ];
          };
        };

        # 不建 swap 分区：swap 由 zram 提供（见 modules/nixos/optimize.nix）
        root = {
          size = "100%";
          uuid = "920364df-a419-4f32-a53d-ddb25e0cabf5";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "/root" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd" ];
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd" ];
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [ "noatime" "compress=zstd" ];
              };
            };
          };
        };
      };
    };
  };
}
