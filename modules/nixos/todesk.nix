# modules/nixos/todesk.nix
{ config, lib, pkgs, userSettings, ... }:

let
  systemctl = "${config.systemd.package}/bin/systemctl";

  # ToDesk 的 GTK/sciter 前端只支持 X11，GDK 选中 Wayland 后端时会 SIGSEGV。
  # 另外 driftwm 的 xwayland-satellite 比 foot --server 晚就绪，从 foot 里
  # 起的 shell 可能没有 DISPLAY，所以这里再从 X socket 里兜底找一次。
  todesk-x11 = pkgs.writeShellScriptBin "todesk" ''
    export GDK_BACKEND=x11

    # libzrtc 自带一套 tcmalloc 并且导出了 realloc。GTK 初始化时会探测
    # GLX，NVIDIA 的 libGLX 经 libxcb 调 realloc 时会被替换成 libzrtc 的
    # 分配器，指针对不上直接 SIGSEGV（core 里停在
    # gdk_x11_screen_init_gl -> glXQueryServerString -> realloc）。
    # 关掉 GDK 的 GL 探测，不走 GLX 就不会触发；ToDesk 界面软件渲染足够。
    export GDK_GL=disable
    if [ -z "''${DISPLAY:-}" ]; then
      for sock in /tmp/.X11-unix/X*; do
        if [ -S "$sock" ]; then
          export DISPLAY=":''${sock##*/X}"
          break
        fi
      done
    fi

    # todeskd 不再开机自启，第一次打开 GUI 时按需拉起。
    # -n：没有免密 sudo 时直接失败，不要在图形启动器里卡住等密码。
    if ! ${systemctl} is-active --quiet todeskd.service; then
      ${config.security.wrapperDir}/sudo -n ${systemctl} start todeskd.service \
        || echo "todesk: todeskd.service 启动失败，远程控制可能不可用" >&2
    fi

    exec ${pkgs.todesk}/bin/todesk "$@"
  '';
in
{
  services.todesk.enable = true;

  # 平时用得少，不需要开机常驻；由上面的 wrapper 按需启动。
  systemd.services.todeskd.wantedBy = lib.mkForce [ ];
  
  home-manager.users.${userSettings.username} = { pkgs, config, ... }: {
    home.packages = with pkgs; [ todesk-x11 ];

    # 覆盖系统里指向原版 bwrap 包装器的 .desktop，fuzzel 等桌面启动器
    # 也会走强制 X11 的 wrapper。
    xdg.dataFile."applications/todesk.desktop".text = ''
      [Desktop Entry]
      Version=4.7.2.0
      Encoding=UTF-8
      Name=ToDesk
      Comment=ToDesk Remote Control Software
      Comment[zh_CN]=ToDesk远程控制软件
      Exec=todesk
      Icon=todesk
      GenericName=ToDesk Remote Control Software
      GenericName[zh_CN]=ToDesk远程控制软件
      Keywords=todesk
      Categories=Network;
      Type=Application
      Terminal=false
    '';
  };
}
