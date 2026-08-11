{ config, lib, pkgs, userSettings, ... }:
let
  liveConfig = "${userSettings.dotfilesDir}/assets/config.dae";
in
{
  services.dae = {
    enable = true;
    configFile = pkgs.writeText "dae-dummy" "global { lan_interface: auto; wan_interface: auto; }";
    assets = with pkgs; [ v2ray-geoip v2ray-domain-list-community ];
  };

  systemd.services.dae.serviceConfig = {
    LoadCredential = lib.mkForce [ ];
    ExecStartPre = lib.mkForce [ "" "${pkgs.dae}/bin/dae validate -c ${liveConfig}" ];
    ExecStart = lib.mkForce [ "" "${pkgs.dae}/bin/dae run --disable-timestamp -c ${liveConfig}" ];
  };

  systemd.services.dae.wantedBy = lib.mkForce [ ];
  systemd.services.dae.requiredBy = lib.mkForce [ ];
}
