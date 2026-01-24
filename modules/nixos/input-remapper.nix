{ config, lib, pkgs, ... }:
{
  services.input-remapper.enable = true;
  systemd.services.input-remapper.wantedBy = lib.mkForce [];
}
