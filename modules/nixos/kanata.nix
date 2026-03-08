{ config, lib, pkgs, ... }:
{
  services.kanata = {
    enable = true;
    keyboards.default.config = ''
      (defsrc
        n
      )

      (deflayer base
        (macro spc l)
      )
    '';
  };

  systemd.services.kanata-default = {
    wantedBy = lib.mkForce [ ];
    serviceConfig = {
      DeviceAllow = [ "/dev/uinput rw" ];
    };
  };
}

