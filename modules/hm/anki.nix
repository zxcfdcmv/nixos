{ config, pkgs, ... }:

{
  programs.anki = {
    enable = true;
    language = "zh-CN";
    theme = "followSystem";
    uiScale = 1.0;
    videoDriver = "vulkan";
    reduceMotion = true;
    style = "native";
  };
}
