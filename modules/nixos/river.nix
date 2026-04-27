{ config, pkgs, lib, userSettings, ... }:

let
  finalKwmConfig = pkgs.replaceVars ../../assets/kwm-config.zon {
    # 定义占位符对应的真实路径
    # 注意：变量名必须与 .zon 里的 @变量名@ 一致
    stylix_image = "${config.stylix.image}";
    swaybg = "${pkgs.swaybg}/bin/swaybg";
    fuzzel = "${pkgs.fuzzel}/bin/fuzzel";
    footserver = "${pkgs.foot}/bin/foot";
    footclient = "${pkgs.foot}/bin/footclient";
    mako = "${pkgs.mako}/bin/mako";
    xdg_wlr = "${pkgs.xdg-desktop-portal-wlr}/libexec/xdg-desktop-portal-wlr";
    xdg_gtk = "${pkgs.xdg-desktop-portal-gtk}/libexec/xdg-desktop-portal-gtk";
    
    fg = config.lib.stylix.colors.base05;
    bg = config.lib.stylix.colors.base00;
    accent = config.lib.stylix.colors.base0D;
    dim = config.lib.stylix.colors.base03;
    font = "Maple Mono NF CN";
  };

  kwm = pkgs.stdenv.mkDerivation rec {
    pname = "kwm";
    version = "master";
    src = pkgs.fetchzip {
      url = "${userSettings.githubProxy}/https://github.com/kewuaa/kwm/archive/refs/heads/master.zip";
      sha256 = "sha256-+5iwQowxxbUSvVx29r7QOG63ssnBxmn4BeMLynlO0Gw=";
      stripRoot = true;
    };

    nativeBuildInputs = [
      pkgs.zig_0_15
      pkgs.pkg-config
      pkgs.wayland-scanner
      pkgs.makeWrapper
    ];

    buildInputs = [
      pkgs.wayland
      pkgs.wayland-protocols
      pkgs.libxkbcommon
      pkgs.pixman
      pkgs.fcft
    ];

    postPatch = ''
      cp ${finalKwmConfig} config.zon
    '';

    buildPhase = ''
      runHook preBuild
      zig build -Dconfig=config.zon -Doptimize=ReleaseSafe -Dtarget=x86_64-linux-gnu.2.38 -Dcpu=baseline --release=safe
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp zig-out/bin/kwm $out/bin/kwm.real

      wrapProgram $out/bin/kwm.real \
        --set LD_LIBRARY_PATH "${pkgs.wayland}/lib:${pkgs.libxkbcommon}/lib:${pkgs.pixman}/lib:${pkgs.fcft}/lib" \
        --prefix PATH : "${pkgs.fcft}/bin"

      mv $out/bin/kwm.real $out/bin/kwm
      runHook postInstall
    '';
  };

  kwmBarScript = pkgs.writeShellScriptBin "kwm-status" ''
    #!/usr/bin/env bash
    export PATH="${lib.makeBinPath (with pkgs; [ coreutils wireplumber brightnessctl ])}:$PATH"

    while true; do
      # 1. 音量 (NixOS 自带 wpctl)
      VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{printf "%d%%",$2*100}')

      # 2. 亮度 (改用 awk 提取，避免正则兼容性问题)
      BRI=$(brightnessctl info 2>/dev/null | awk -F'[()]' '/Current brightness/{print$2}')

      # 3. 内存 (纯读 /proc/meminfo)
      MEM=$(awk '/MemAvailable/{a=$2} /MemTotal/{t=$2} END {printf "%.1fG", (t-a)/1024/1024}' /proc/meminfo)

      # 4. CPU (最基础的算术，不依赖任何高级特性)
      read -r cpu_user cpu_nice cpu_sys cpu_idle cpu_iowait _ _ _ < /proc/stat
      idle1=$((cpu_idle + cpu_iowait))
      total1=$((cpu_user + cpu_nice + cpu_sys + idle1))
      
      sleep 1
      
      read -r cpu_user cpu_nice cpu_sys cpu_idle cpu_iowait _ _ _ < /proc/stat
      idle2=$((cpu_idle + cpu_iowait))
      total2=$((cpu_user + cpu_nice + cpu_sys + idle2))
      
      diff_idle=$((idle2 - idle1))
      diff_total=$((total2 - total1))
      
      if [ "$diff_total" -gt 0 ]; then
        CPU=$((100 * (diff_total - diff_idle) / diff_total))%
      else
        CPU="?"
      fi

      # 5. 时间
      TIME=$(date '+%Y/%m/%d %H:%M')

      # 6. 拼接输出 
      # ^#AARRGGBB 换颜色，^#! 恢复默认颜色
      echo "^#88ccffffV:''${VOL}^#! ^#ffcc88ffB:''${BRI}^#! ^#88ff88ffC:''${CPU}^#! ^#ff8888ffM:''${MEM}^#! ''${TIME}"

      sleep 3
    done
  '';
  riverInitScript = pkgs.writeShellScript "river-init" ''
    # 把我们自己写的脚本管道给 kwm
    exec ${kwmBarScript}/bin/kwm-status |${kwm}/bin/kwm
  '';
in {
  # --- 系统级配置 ---
  environment.systemPackages = [
    pkgs.river
    kwm
  ];

  services.greetd = {
    enable = true;
    settings.default_session.command = ''
      ${pkgs.tuigreet}/bin/tuigreet \
        --cmd "${pkgs.river}/bin/river -c ${riverInitScript}" \
        --theme "dark" \
        --greet-align center \
        --time \
        --time-format "%A, %d %B %Y %H:%M:%S" \
        --remember \
    '';
  };
}
