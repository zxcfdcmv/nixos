# modules/hm/mpv.nix
{ config, pkgs, ... }:
{
  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      uosc
      thumbfast
      bdanmaku
      sponsorblock
      quality-menu
      reload
    ];
    config = {
      osc = "no";
      border = "no";
      "osd-bar" = "no";

      "sub-auto" = "no"; 
      cache = "yes";
      "cache-secs" = 20;               # 预缓存 20 秒，避免断流
      "demuxer-max-bytes" = "150MiB";   # 限制前向缓存大小，防止疯狂占内存
      "ytdl-format" = "bestvideo[height<=1080]+bestaudio/best"; # 限制解析最高 1080P，1080P DASH 流握手最快
      # script-opts = "thumbfast-network=yes"; # 进度条缩略图
    };
  };
}
