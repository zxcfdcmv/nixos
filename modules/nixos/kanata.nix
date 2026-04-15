{ config, lib, pkgs, ... }:
{
  services.kanata = {
    enable = true;
    keyboards.default = {
      # 必须包含鼠标设备，否则 Kanata 监听不到点击
      devices = [
        "/dev/input/by-id/usb-E-Signal_USB_Gaming_Keyboard-event-kbd"
        "/dev/input/by-id/usb-E-Signal_USB_Gaming_Mouse-mouse"
      ];

      config = ''
        (defsrc
          1 2 3 4   ;; 数字键用于切换
          mlft      ;; 鼠标左键
        )

        (defalias
          ;; 切换层的动作
          to-norm (layer-switch base)       ;; 切换回普通层
          to-game (layer-switch game-mode)  ;; 切换到游戏层

          ;; 游戏宏：左键 -> 延迟5ms -> 右键
          ;; (macro 键 延迟 键)
          l-delay-r (macro mlft 5 mrgt)
        )

        ;; [普通层]
        (deflayer base
          1       2       @to-game 4        ;; 按 3 进游戏层，其余切回/保持
          mlft                              ;; 保持原样
        )

        ;; [游戏层]
        (deflayer game-mode
          @to-norm @to-norm 3      @to-norm ;; 按 1,2,4 切回普通层
          @l-delay-r                        ;; 关键：点击左键触发宏
        )
      '';
    };
  };

  systemd.services.kanata-default = {
    wantedBy = lib.mkForce [ ];
    serviceConfig = {
      DeviceAllow = [
        "/dev/uinput rw"
        "/dev/input/event*"
      ];
    };
  };
}

