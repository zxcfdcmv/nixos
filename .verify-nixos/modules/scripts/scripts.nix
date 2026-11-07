# modules/scripts/scripts.nix
{ config, pkgs, userSettings, ... }:
let
  customCommands = [
    "toggle-fcitx"
    "toggle-dae"
    "toggle-warp"
    "toggle-docker"
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

    # toggle-warp - 系统服务
    (mkSystemToggleService "toggle-warp" "cloudflare-warp")

    # toggle-docker
    (mkSystemToggleService "toggle-docker" "docker")

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
      nh os switch .
    '') 

    (writeShellScriptBin "my-switch-up" ''
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

    (writeShellScriptBin "toggle-gopeed" ''
      if driftwm msg state | rg -q '#[0-9]+ gopeed'; then
          driftwm msg close gopeed
      else
          gopeed
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

    (writeShellScriptBin "my-copy" ''
      TEXT=$(copyq clipboard)
      [ -n "$TEXT" ] && echo -n "$TEXT" | curl -s --data-binary @- https://paste-6bw.pages.dev/${userSettings.username}
    '')

    (writeShellScriptBin "my-paste" ''
      TEXT=$(curl -s -f https://paste-6bw.pages.dev/${userSettings.username})
      [ -z "$TEXT" ] && exit 0

      copyq copy "$TEXT"
      copyq copy text/plain "$TEXT" && copyq select 0
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

    (writeShellScriptBin "gitp" ''
      #!/bin/bash
      GIT="${pkgs.git}/bin/git"
      DATE="${pkgs.coreutils}/bin/date"

      # 1. 检查工作区是否有未提交的修改
      HAS_CHANGES=false
      if [ -n "$($GIT status --porcelain)" ]; then
          HAS_CHANGES=true
      fi

      # 2. 检查本地是否有尚未推送到远程的 Commit
      # (获取当前分支和远程追踪分支的差异，如果有输出，说明有未 push 的提交)
      HAS_UNPUSHED=false
      if $GIT rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
          if [ -n "$($GIT log @{u}..HEAD --oneline)" ]; then
              HAS_UNPUSHED=true
          fi
      else
          # 如果根本没有建立远程追踪分支，且工作区是干净的，就认为有需要推送（或让 git push 报错提示）
          if [ "$HAS_CHANGES" = "false" ]; then
              HAS_UNPUSHED=true
          fi
      fi

      # 3. 如果既没有新修改，也没有未推送的 commit，才真正拦截
      if [ "$HAS_CHANGES" = "false" ] && [ "$HAS_UNPUSHED" = "false" ]; then
          echo "✨ 没有发现任何新修改或未推送的提交，无需操作！"
          exit 0
      fi

      # 4. 只有在有新修改时，才进行 add 和 commit
      if [ "$HAS_CHANGES" = "true" ]; then
          current_time=$($DATE "+%Y-%m-%d %H:%M:%S")
          if [ -z "$1" ]; then
              commit_msg="Auto-sync: ''${current_time}"
          else
              commit_msg="$1"
          fi

          echo "📝 发现新修改，正在提交..."
          $GIT add .
          if ! $GIT commit -m "''${commit_msg}"; then
              echo "❌ Commit 失败！"
              exit 1
          fi
      fi

      # 5. 执行推送，并检查推送结果
      echo "🚀 开始自动推送..."
      if $GIT push; then
          echo "🎉 推送成功！"
      else
          echo "❌ 推送失败！请检查网络或执行 git pull 解决冲突。"
          exit 1
      fi
    '')

    (writeShellScriptBin "play_with_mpv" ''
      ${pkgs.wtype}/bin/wtype -k ctrl -k alt -k shift

      ${pkgs.wtype}/bin/wtype -M ctrl -k l -m ctrl
      sleep 0.1

      ${pkgs.wtype}/bin/wtype -M ctrl -k c -m ctrl
      sleep 0.15

      ${pkgs.wtype}/bin/wtype -M ctrl -k w -m ctrl

      URL=$(${pkgs.wl-clipboard}/bin/wl-paste)

      if [[ "$URL" == http* ]]; then
         mpv --force-window=yes --terminal=no "$URL" &
      fi
    '')

    (writeShellScriptBin "zed-ai" ''
      export CF_GATEWAY_API_KEY="$(rbw get cloudflare-aig)"
      export OPENCODE_API_KEY="$(rbw get ai-opencode)"
      export OPENROUTER_API_KEY="$(rbw get cloudflare-aig)" 
      exec ${pkgs.zed-editor}/bin/zeditor "$@"
    '')
  ])
  ++ builtins.map mkDesktop customCommands;  
}
