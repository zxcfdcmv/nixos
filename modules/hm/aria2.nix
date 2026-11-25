# modules/hm/aria2.nix
# aria2 常驻下载器：HTTP/FTP/BT/磁力，RPC 只监听本机。
# 界面由浏览器扩展 Aria2 Explorer 提供（内置 AriaNg），
# 所以这里只跑 aria2 本体，不再启动本地静态站点。
{ config, pkgs, ... }:
let
  rpcSecret = "aria2-local";
in
{
  home.packages = [ pkgs.aria2 ];

  xdg.configFile."aria2/aria2.conf".text = ''
    # 下载目录
    dir=${config.home.homeDirectory}/Downloads

    # 断点续传与并发
    continue=true
    split=16
    max-concurrent-downloads=5

    # RPC：只监听 127.0.0.1；浏览器扩展与 RPC 不同 origin，需要 allow-origin
    enable-rpc=true
    rpc-listen-all=false
    rpc-listen-port=6800
    rpc-allow-origin-all=true
    rpc-secret=${rpcSecret}

    # BT / 磁力
    listen-port=6881-6999
    seed-ratio=1.0
    bt-enable-lpd=true

    # 会话保存：重启后恢复未完成任务
    save-session=${config.home.homeDirectory}/.local/state/aria2/aria2.session
    input-file=${config.home.homeDirectory}/.local/state/aria2/aria2.session
    save-session-interval=30
  '';

  systemd.user.services.aria2 = {
    Unit.Description = "aria2 download daemon";
    Service = {
      ExecStartPre = [
        "${pkgs.coreutils}/bin/mkdir -p %h/.local/state/aria2"
        "${pkgs.coreutils}/bin/touch %h/.local/state/aria2/aria2.session"
      ];
      ExecStart = "${pkgs.aria2}/bin/aria2c --conf-path=%h/.config/aria2/aria2.conf";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
