{ config, lib, pkgs, userSettings, ... }:
{
  services.dae = {
    enable = true;
    config = ''
      global {
        lan_interface: eno1, wlp4s0, cni0, flannel.1
        wan_interface: auto
        log_level: warn
        dial_mode: ip
        check_interval: 300s
        allow_insecure: true
      }

      subscription {
        # 'https://proxy.v2gh.com/https://raw.githubusercontent.com/Pawdroid/Free-servers/main/sub'
        "${userSettings.githubProxy}/https://raw.githubusercontent.com/free18/v2ray/refs/heads/main/v.txt"
        # 'https://gh-proxy.com/raw.githubusercontent.com/chengaopan/AutoMergePublicNodes/master/list.txt'
        # 'https://gh-proxy.com/raw.githubusercontent.com/Barabama/FreeNodes/main/nodes/nodev2ray.txt'
      }

      dns {
        upstream {
          alidns: 'udp://223.5.5.5:53'
          googledns: 'tcp+udp://8.8.8.8:53'
        }
        routing {
          request {
            qname(geosite:cn) -> alidns
            qname(geosite:google,geosite:telegram,geosite:github) -> googledns
            fallback: alidns
          }
          response {
            upstream(alidns) && !ip(geoip:cn) -> googledns
            fallback: accept
          }
        }
      }

      group {
        proxy {
          policy: min_moving_avg
        }
      }

      routing {
        pname(NetworkManager, systemd, dhclient) -> direct
        domain(geosite:cn) -> direct
        domain(keyword:gh-proxy) -> direct
        domain(keyword:steamstatic) -> direct
        dip(geoip:private) -> direct
        dip(geoip:cn) -> direct

        domain(keyword:steamcommunity,steampowered) -> proxy
        domain(geosite:telegram,geosite:google,geosite:github) -> proxy

        fallback: proxy
      }
    '';
  };

  systemd.services.dae.wantedBy = lib.mkForce [ ];
  systemd.services.dae.requiredBy = lib.mkForce [ ];


  # 登录后自启dae

  # systemd.user.services.start-dae-after-niri = {
  #   description = "Start system-wide dae after Niri session starts";
  #   partOf = [ "graphical-session.target" ];
  #   wantedBy = [ "graphical-session.target" ];
  #   after    = [ "graphical-session.target" ];

  #   serviceConfig = {
  #     ExecStart = "${pkgs.systemd}/bin/systemctl --no-block start dae";
  #     ExecStop = "${pkgs.systemd}/bin/systemctl stop dae";

  #     Type = "oneshot";
  #     RemainAfterExit = "yes";
  #   };
  # };

  # security.polkit.extraConfig = ''
  #   polkit.addRule(function(action, subject) {
  #     if (action.id == "org.freedesktop.systemd1.manage-units" &&
  #         action.lookup("unit") == "dae.service" &&
  #         subject.isInGroup("wheel")) {
  #       return polkit.Result.YES;
  #     }
  #   });
  # '';
}
