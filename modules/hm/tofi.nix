{ config, pkgs, ... }:
{
  programs.tofi = {
    enable = true;
    settings = {
      num-results = 0;
      height = "50";
      width = "30%";
      
      anchor = "top";
      margin-top = 10;
      border-width = 2;
      outline-width = 0;
      corner-radius = 6;
      prompt-text = "❯ ";
      prompt-padding = 10;
      padding-left = "15";
      padding-right = "15";
      padding-top = "6";

      hide-cursor = true;
      text-cursor = true;
      fuzzy-match = true;
      require-match = true;
      auto-accept-single = true;

      history = false;           # 禁用历史排序！
    };
  };
}
