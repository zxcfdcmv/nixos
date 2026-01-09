{ config, lib, pkgs, ... }:
{
  services.dae = {
    enable = true;

    config = ''
      global {
        lan_interface: auto
        wan_interface: auto
        log_level: warn
        dial_mode: ip
        check_interval: 300s
        allow_insecure: true
      }

      subscription {
        # 'https://gh-proxy.com/raw.githubusercontent.com/chengaopan/AutoMergePublicNodes/master/list.meta.yml'
        # 'https://proxy.v2gh.com/https://raw.githubusercontent.com/Pawdroid/Free-servers/main/sub'
        # 'https://gh-proxy.com/raw.githubusercontent.com/snakem982/proxypool/main/source/clash-meta.yaml'
        # 'https://gh-proxy.com/raw.githubusercontent.com/snakem982/proxypool/main/source/clash-meta-2.yaml'
        'https://gh-proxy.com/raw.githubusercontent.com/free18/v2ray/refs/heads/main/v.txt'
      }

      dns {
        upstream {
          alidns: 'udp://223.5.5.5:53'
          tencentdns: 'udp://119.29.29.29:53'
        }
        routing {
          request {
            qname(geosite:cn) -> alidns
            fallback: tencentdns
          }
          response {
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
        domain(keyword:gh-proxy) -> direct

        domain(keyword:steamcommunity,steampowered) -> proxy
        domain(keyword:steamstatic) -> direct

        domain(geosite:cn) -> direct
        dip(geoip:private) -> direct
        dip(geoip:cn) -> direct

        fallback: proxy
      }
    '';
  };
}
