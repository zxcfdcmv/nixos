# 本文件只保留「这台机器是什么硬件」的探测结果，不再包含磁盘 / UUID。
# 磁盘布局见 modules/disko.nix；hostPlatform 由 flake.nix 的 `system` 决定。
# 换机器后可以直接重新生成本文件，不会影响分区方案。
{ config, lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" "uinput" ];
  boot.extraModulePackages = [ ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
