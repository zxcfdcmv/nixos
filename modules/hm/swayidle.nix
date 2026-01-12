{ config, pkgs, ... }:
{
  services = {
    swayidle = {
      enable = true;
      systemdTarget = "graphical-session.target";
      timeouts = [
        {
          timeout = 300;
          command = "noctalia-shell ipc call lockScreen lock";
        }
        {
          timeout = 600;
          command = "niri msg action power-off-monitors";
          resumeCommand = "niri msg action power-on-monitors";
        }
      ];
      events = {
        before-sleep = "noctalia-shell ipc call lockScreen lock";
        lock = "noctalia-shell ipc call lockScreen lock";
      };
    };
  };
}
