{ config, lib, pkgs, ... }:
{
  services.dae = {
    enable = true;

    config = ''
      global {
        lan_interface: auto
        wan_interface: auto
        log_level: info
        allow_insecure: true
      }

      subscription {
        # 'https://gh-proxy.com/raw.githubusercontent.com/chengaopan/AutoMergePublicNodes/master/list.meta.yml'
        # 'https://proxy.v2gh.com/https://raw.githubusercontent.com/Pawdroid/Free-servers/main/sub'
        # 'https://gh-proxy.com/raw.githubusercontent.com/snakem982/proxypool/main/source/clash-meta.yaml'
        # 'https://gh-proxy.com/raw.githubusercontent.com/snakem982/proxypool/main/source/clash-meta-2.yaml'
        'https://gh-proxy.com/raw.githubusercontent.com/free18/v2ray/refs/heads/main/v.txt'
      }

      group {
        proxy {
          policy: min_moving_avg
        }
      }

      routing {
        domain(keyword:gh-proxy) -> direct
        domain(keyword:steamcommunity) -> proxy
        domain(keyword:steampowered) -> proxy
        domain(keyword:steamstatic) -> direct

        dip(geoip:private) -> direct
        dip(geoip:cn) -> direct
        fallback: proxy
      }
    '';
  };
}
