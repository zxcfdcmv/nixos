{ config, pkgs, lib, userSettings, ... }:

let
  runtimeDir = "/run/user/${toString config.home.uid}";
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
        
        mkdir -p "${runtimeDir}"
        chmod 700 "${runtimeDir}"
        
        if ! rbw unlocked 2>/dev/null; then
          echo "Unlocking Bitwarden..."
          rbw unlock
        fi
        
        rbw get "${config.bitwardenSops.keyName}" > "${ageKeyPath}.tmp"
        chmod 600 "${ageKeyPath}.tmp"
        mv "${ageKeyPath}.tmp" "${ageKeyPath}"
        
        echo "SOPS age key ready"
      '')
      
      (writeShellScriptBin "sops-lock" ''
        rm -f "${ageKeyPath}"
        rbw lock 2>/dev/null || true
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
