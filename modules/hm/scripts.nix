# modules/hm/scripts.nix
{ config, pkgs, userSettings, ... }:
let
  customCommands = [
    "toggle-fcitx"
    "toggle-dae"
    "game-cs2-cn"
    "game-cs2-global"
    "game-low"
    "game-high"
    "cdda"
    "zed_nixos"
  ];

  mkDesktop = cmd: pkgs.makeDesktopItem {
    name = cmd;
    desktopName = cmd;
    exec = cmd;
    terminal = false;
    categories = [ "Utility" ];
  };

  mkSystemToggleService = name: service: pkgs.writeShellScriptBin name ''
    SERVICE="${service}.service"
    CMD="sudo systemctl"
    
    STATUS=$($CMD is-active "$SERVICE" 2>/dev/null || echo "inactive")

    notify() {
      local title="$1"
      local urgency="$2"
      # noctalia-shell ipc call toast send "{\"title\":\"$title\",\"type\":\"$type\"}"
      ${pkgs.libnotify}/bin/notify-send -u "$urgency" "$title"
    }

    case "$STATUS" in
      active)
        $CMD stop "$SERVICE"
        notify "⚫ $SERVICE Disabled" "low"
        ;;
      *)
        $CMD start "$SERVICE"
        notify "🟢 $SERVICE Enabled" "normal"
        ;;
    esac
  '';

  mkFcitx5ToggleService = pkgs.writeShellScriptBin "toggle-fcitx" ''
    notify() {
      local title="$1"
      local urgency="$2"
      # noctalia-shell ipc call toast send "{\"title\":\"$title\",\"type\":\"$type\"}"
      ${pkgs.libnotify}/bin/notify-send -u "$urgency" "$title"
    }

    if pidof fcitx5 >/dev/null 2>&1; then
        pkill fcitx5
        sleep 0.5
        if pidof fcitx5 >/dev/null 2>&1; then
            pkill -9 fcitx5
        fi
        notify "⚫ Fcitx5 Disabled" "low"
    else
        fcitx5 -d
        notify "🟢 Fcitx5 Enabled" "normal"
    fi
  '';
in
{
  home.packages = (with pkgs; [
    mkFcitx5ToggleService

    # toggle-dae - 系统服务
    (mkSystemToggleService "toggle-dae" "dae")

    (writeShellScriptBin "rust-project-gui" ''
      exec nix-shell ~/nixos/modules/project/rust-gui.nix
    '') 

    (writeShellScriptBin "rust-project-cli" ''
      exec nix-shell ~/nixos/modules/project/rust-cli.nix
    '') 
  
    (writeShellScriptBin "game-cs2-cn" ''
      steam -applaunch 730 -novid -perfectworld +exec autoexec.cfg
    '') 
    (writeShellScriptBin "game-cs2-global" ''
      steam -applaunch 730 -novid +exec autoexec.cfg
    '') 

    # x11
    (writeShellScriptBin "game-low" ''
      ${pkgs.linuxPackages.nvidia_x11.settings}/bin/nvidia-settings --assign CurrentMetaMode="DP-2: 1920x1080 @800x600 +0+0 {ViewPortIn=800x600, ViewPortOut=1920x1080+0+0, ResamplingMethod=Bilinear}"
    '')

    (writeShellScriptBin "game-high" ''
      ${pkgs.linuxPackages.nvidia_x11.settings}/bin/nvidia-settings --assign CurrentMetaMode="DP-2: 1920x1080 @1920x1080 +0+0 {ViewPortIn=1920x1080, ViewPortOut=1920x1080+0+0}"
    '')

    (writeShellScriptBin "my-switch" ''
      cd ${userSettings.dotfilesDir}
      git add .
      nh os switch . --update
    '') 

    (writeShellScriptBin "my-switch-bak" ''
      cd ${userSettings.dotfilesDir}
      git add .
      nix flake update
      sudo nice -n 19 ionice -c 3 nixos-rebuild switch --flake .#${userSettings.hostName}
    '') 

    (writeShellScriptBin "kanata-l4d2" ''
      cd ${userSettings.dotfilesDir}
      sudo -E ${pkgs.kanata}/bin/kanata -c assets/kanata/l4d2/l4d2-mouse.kbd &
      PID_MOUSE=$!
      sudo -E ${pkgs.kanata}/bin/kanata -c assets/kanata/l4d2/l4d2-bhop.kbd &
      PID_BHOP=$!
      trap 'kill $PID_MOUSE $PID_BHOP 2>/dev/null' EXIT
      wait
    '')

    (writeShellScriptBin "kanata-wf" ''
      cd ${userSettings.dotfilesDir}
      sudo -E ${pkgs.kanata}/bin/kanata -c assets/kanata/witchfire/wf.kbd &
      PID_MOUSE=$!
      sudo -E ${pkgs.kanata}/bin/kanata -c assets/kanata/witchfire/wf-hong.kbd &
      PID_BHOP=$!
      trap 'kill $PID_MOUSE $PID_BHOP 2>/dev/null' EXIT
      wait
    '')

    (writeShellScriptBin "toggle-copyq" ''
      VISIBLE=$(xdotool search --onlyvisible --class "copyq" 2>/dev/null | head -1)

      if [ -n "$VISIBLE" ]; then
          xdotool windowunmap "$VISIBLE"
      else
          copyq toggle 2>/dev/null
          copyq toggle 2>/dev/null
          copyq show
      fi
    '')

    (writeShellScriptBin "zed_nixos" ''
      zeditor -n ${userSettings.dotfilesDir}
    '')

    (writeShellScriptBin "cowyo-up" ''
      TEXT=$(copyq clipboard)
      [ -z "$TEXT" ] && exit 1

      echo -n "$TEXT" | curl -s --data-binary @- https://cowyo.com/${userSettings.username}
    '')

    (writeShellScriptBin "cowyo-down" ''
      TEXT=$(curl -s https://cowyo.com/${userSettings.username})
      [ -z "$TEXT" ] && exit 1
      copyq copy "$TEXT"
      copyq add "$TEXT"
    '')

    (writeShellScriptBin "croc-send" ''
      export CROC_SECRET=${userSettings.username}

      # FILE=$(find ~/{Downloads,Documents,Pictures} -maxdepth 3 -type f 2>/dev/null | fzf --prompt="选择文件 > ")
      FILE=$(fd --type f --max-depth 3 . ~/Downloads ~/Documents ~/Pictures 2>/dev/null | fzf --prompt="选择文件 > ")

      if [ -n "$FILE" ]; then
          croc send "$FILE"
      fi
    '')

    (writeShellScriptBin "croc-recv" ''
      export CROC_SECRET=${userSettings.username}
      mkdir -p ~/Downloads/croc
      croc --yes --overwrite --out ~/Downloads/croc
    '')

    (pkgs.writeShellScriptBin "gitp" ''
      #!/bin/bash
      # 显式指定需要的依赖路径，防止 NixOS 找不到命令
      GIT="${pkgs.git}/bin/git"
      DATE="${pkgs.coreutils}/bin/date"

      # 1. 检查是否有未追踪或修改的文件
      if [ -z "$($GIT status --porcelain)" ]; then
          echo "✨ 没有发现任何修改，无需推送！"
          exit 0
      fi

      # 2. 获取当前时间戳
      current_time=$($DATE "+%Y-%m-%d %H:%M:%S")

      # 3. 判断自定义 commit 信息
      if [ -z "$1" ]; then
          commit_msg="Auto-sync: ''${current_time}" # 注意：Nix 字符串里 $ 符号前如果是双单引号表示转义
      else
          commit_msg="$1"
      fi

      # 4. 执行一键三连
      echo "🚀 开始自动推送..."
      $GIT add .
      $GIT commit -m "''${commit_msg}"
      $GIT push

      echo "🎉 推送成功！提交信息: [''${commit_msg}]"
    '')
  ])
  ++ builtins.map mkDesktop customCommands;  
}
