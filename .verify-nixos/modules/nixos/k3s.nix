{ config, lib, pkgs, userSettings, ... }:
{
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--disable" "traefik"
      "--disable" "servicelb"
      "--system-default-registry" "registry.cn-hangzhou.aliyuncs.com"
    ];
  };

  # 国内镜像源配置
  environment.etc."rancher/k3s/registries.yaml".text = ''
    mirrors:
      docker.io:
        endpoint:
          - "https://docker.m.daocloud.io"
          - "https://docker.io"
      quay.io:
        endpoint:
          - "https://quay.m.daocloud.io"
          - "https://quay.io"
      registry.k8s.io:
        endpoint:
          - "https://k8s.m.daocloud.io"
          - "https://registry.k8s.io"
      gcr.io:
        endpoint:
          - "https://gcr.m.daocloud.io"
          - "https://gcr.io"
      ghcr.io:
        endpoint:
          - "https://ghcr.m.daocloud.io"
          - "https://ghcr.io"
  '';

  # 防火墙配置
  networking = {
    hosts = {
      "127.0.0.10" = [
        "jenkins.local"
        "argocd.local"
        "harbor.local"
        "nginx.local"
        "prometheus.local"
        "grafana.local"
      ];     
    };
    firewall = {
      allowedTCPPorts = [ 6443 2379 2380 10250 10251 10252 2376 ];
      allowedUDPPorts = [ 8472 51820 51821 ];
    };
  };

  systemd.tmpfiles.rules = [
    "C /home/${userSettings.username}/.kube/config 0600 ${userSettings.username} users - /etc/rancher/k3s/k3s.yaml"
  ];

  # 同时建 .kube 目录
  system.activationScripts.kubeconfig = ''
    mkdir -p /home/${userSettings.username}/.kube
    chown ${userSettings.username}:users /home/${userSettings.username}/.kube
  '';

  security.sudo.extraRules = [{
    users = [ userSettings.username ];
    commands = [{
      command = "${pkgs.kubectl}/bin/kubectl";
      options = [ "NOPASSWD" "SETENV" ];
    }];
  }];

  systemd.services.k3s.wantedBy = lib.mkForce [ ];

  home-manager.users.${userSettings.username} = { config, ...}: {
    home.packages = with pkgs; [
      kubectl
      k9s
      kubernetes-helm
      argocd
    ];

    home.sessionVariables = {
      KUBECONFIG = "/home/${userSettings.username}/.kube/config";
    };
  };
}
