{ config, pkgs, lib, userSettings, ... }:

let
  runtimeDir = "/run/user/1000";  # 或者 "${toString config.home.uid}" 如果可用
  ageKeyPath = "${runtimeDir}/sops-age-key";
in
{
  options.bitwardenSops = {
    enable = lib.mkEnableOption "Bitwarden-backed SOPS age key";
    keyName = lib.mkOption {
      type = lib.types.str;
      default = "sops-age-key";
    };
  };

  config = lib.mkIf config.bitwardenSops.enable {
    programs.rbw = {
      enable = true;
      settings = {
        email = "${userSettings.username}@outlook.com";
        pinentry = pkgs.pinentry-tty;
      };
    };

    home.packages = with pkgs; [
      pinentry-tty
      (writeShellScriptBin "sops-unlock" ''
        set -e
        
        if [ ! -d "${runtimeDir}" ]; then
          echo "Error: ${runtimeDir} does not exist"
          exit 1
        fi
        
        if ! ${pkgs.rbw}/bin/rbw unlocked 2>/dev/null; then
          echo "Unlocking Bitwarden..."
          ${pkgs.rbw}/bin/rbw unlock
        fi
        
        ${pkgs.rbw}/bin/rbw get "${config.bitwardenSops.keyName}" > "${ageKeyPath}.tmp"
        chmod 600 "${ageKeyPath}.tmp"
        mv "${ageKeyPath}.tmp" "${ageKeyPath}"
        
        echo "SOPS age key ready at ${ageKeyPath}"
      '')
      
      (writeShellScriptBin "sops-lock" ''
        rm -f "${ageKeyPath}"
        ${pkgs.rbw}/bin/rbw lock 2>/dev/null || true
        echo "Locked"
      '')
    ];

    home.activation.checkSopsKey = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -f "${ageKeyPath}" ]; then
        printf '\033[33m⚠️  SOPS age key not found. Run "sops-unlock" to fetch from Bitwarden.\033[0m\n'
      fi
    '';
  };
}
