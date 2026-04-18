{ config, lib, pkgs, nix-cachyos-kernel, ... }:
{
  nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ];

  # boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
  services = {
    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
    };
    auto-cpufreq.enable = true;
    scx = {
      enable = true;
      scheduler = "scx_lavd";
      package = pkgs.scx.full;
    };
  };
}
