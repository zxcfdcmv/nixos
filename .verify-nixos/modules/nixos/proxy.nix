# modules/nixos/dae.nix
{ config, lib, pkgs, userSettings, ... }:
let
  liveConfig = "${userSettings.dotfilesDir}/assets/config/dae/config.dae";

  warpCli = "${pkgs.cloudflare-warp}/bin/warp-cli --accept-tos";
  warpSetup = pkgs.writeShellScript "warp-proxy-setup" ''
    # 等 daemon 就绪（最多 30 秒）
    for i in $(seq 1 30); do
      ${warpCli} registration show >/dev/null 2>&1 && break
      sleep 1
    done

    if ${warpCli} registration show 2>&1 | grep -qi "not registered"; then
      ${warpCli} registration new || true
    fi

    ${warpCli} connect          || true
  '';
in
{
  services = {
    dae = {
      enable = true;
      configFile = pkgs.writeText "dae-dummy" "global { lan_interface: auto; wan_interface: auto; }";
      assets = with pkgs; [ v2ray-geoip v2ray-domain-list-community ];
    };

    cloudflare-warp = {
      enable = true;
    };
  };

  systemd.services = {
    dae = {
      wantedBy = lib.mkForce [ ];
      requiredBy = lib.mkForce [ ];
      conflicts = [ "cloudflare-warp.service" ];
      after = [ "cloudflare-warp.service" ];
      serviceConfig = {
        LoadCredential = lib.mkForce [ ];
        ExecStartPre = lib.mkForce [ "" "${pkgs.dae}/bin/dae validate -c ${liveConfig}" ];
        ExecStart = lib.mkForce [ "" "${pkgs.dae}/bin/dae run --disable-timestamp -c ${liveConfig}" ];
      };
    };

    cloudflare-warp = {
      wantedBy = lib.mkForce [ ];
      requiredBy = lib.mkForce [ ];
      conflicts = [ "dae.service" ];
      after = [ "dae.service" ];
      serviceConfig.ExecStartPost = [ "${warpSetup}" ];
    };
  };
}
