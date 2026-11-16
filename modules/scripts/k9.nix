# modules/scripts/k9.nix
#
# k9 —— 通用的「一键清理进程 / 服务」工具。
#
# 设计目标是避开 pkill / killall 的几个坑：
#   1. pkill 默认只比 comm（/proc/PID/comm），最长 15 字符，且区分大小写，
#      所以 `pkill todesk` 打不到 `ToDesk`。
#   2. pkill / killall 都只看进程名，不看 systemd unit，杀完还会被
#      Restart=always 或 watchdog 拉回来。
#   3. 杀不掉往往不是信号不够强，而是进程在 D 状态、是僵尸、或者没权限。
#
# 所以这里做的是：匹配 → 预览 → 停 unit（整 cgroup）→ TERM → 升级 KILL
# → 最后把杀不掉的挑出来并且解释原因。
{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "k9" ''
      set -uo pipefail

      readonly PROG="k9"

      DRY_RUN=0
      ASSUME_YES=0
      USE_FULL=0
      USE_EXACT=0
      FIRST_SIG="TERM"
      ESCALATE=1
      WAIT_SECS=5
      USE_UNITS=1
      DO_DISABLE=0
      VERBOSE=0
      FORCE=0
      PERM_FAIL=0
      PATTERNS=()

      if [ -t 1 ]; then
        B=$'\033[1m'
        DIM=$'\033[2m'
        RED=$'\033[31m'
        GRN=$'\033[32m'
        YEL=$'\033[33m'
        CYN=$'\033[36m'
        RST=$'\033[0m'
      else
        B=""; DIM=""; RED=""; GRN=""; YEL=""; CYN=""; RST=""
      fi

      usage() {
        cat <<'EOF'
      k9 —— 一键清理进程 / systemd 服务

      用法：
        k9 [选项] <关键词> [关键词...]

      默认行为：
        1. 按进程名（comm）做忽略大小写的「包含」匹配；
        2. 同时匹配名字相关的 systemd unit（system 和 user 两套），
           停掉 unit 等于把整个 cgroup 里的子进程一起收拾；
        3. 先发 TERM，等 --timeout 秒，还活着再补 SIGKILL；
        4. 收尾时报告仍然杀不掉的进程，并说明原因
           （D 状态 / 僵尸 / 权限不足 / 被服务重新拉起）。

      选项：
        -n, --dry-run, -l   只列出将要处理的进程和 unit，不动手
        -y, --yes           不询问，直接执行
        -f, --full          同时匹配完整命令行（脚本、python foo.py 之类）
        -x, --exact         进程名精确匹配（默认是包含匹配）
        -k, --kill          首轮就发 SIGKILL，不走 TERM
        -s, --signal SIG    首轮信号，默认 TERM
        -t, --timeout N     每一轮等待秒数，默认 5
            --no-escalate   只发一次信号，不自动补 SIGKILL
            --no-units      不处理 systemd unit，只按 PID 杀
        -d, --disable       顺带把匹配到的 unit disable（不再开机自启）
        -F, --force         允许动受保护的 unit（init/user@/dbus/journald 等）
        -v, --verbose       输出更多细节
        -h, --help          显示本帮助

      示例：
        k9 todesk                # 进程 + todeskd.service 一起清
        k9 -n chrome             # 先看看会动哪些，不执行
        k9 -y -k todesk          # 不问，直接 SIGKILL
        k9 -f train              # 按完整命令行找（字面包含，不是正则）
        k9 -d todesk             # 清掉并把 todeskd 的自动启动也关掉
        sudo k9 todesk           # 有 root 进程时

      退出码：
        0 已清理干净（或 dry-run）   1 没有任何匹配
        2 参数错误                   3 仍有残留
      EOF
      }

      die() { printf "%s错误：%s%s\n" "$RED" "$*" "$RST" >&2; exit 2; }
      warn() { printf "%s注意：%s%s\n" "$YEL" "$*" "$RST" >&2; }
      info() { if [ "$VERBOSE" = 1 ]; then printf "%s%s%s\n" "$DIM" "$*" "$RST" >&2; fi; return 0; }

      # ---------------------------------------------------------------- 基础

      # 一次读完 /proc/<pid>/stat，避开 comm 里带空格 / 括号的坑。
      # 用内建 read 而不是 $(cat file)：不 fork，扫几百个进程时快一个数量级。
      read_stat() {
        local s=""
        RS_STATE=""
        RS_PPID=""
        { IFS= read -r s < "/proc/$1/stat"; } 2>/dev/null
        [ -n "$s" ] || return 1
        s="''${s##*) }"
        RS_STATE="''${s%% *}"
        s="''${s#* }"
        RS_PPID="''${s%% *}"
        [ -n "$RS_STATE" ] && [ -n "$RS_PPID" ]
      }

      # 进程名：内核里的 comm，最长 15 字符。结果放在 RC_COMM 里，避免 fork。
      read_comm() {
        local c=""
        { IFS= read -r c < "/proc/$1/comm"; } 2>/dev/null
        RC_COMM="$c"
        [ -n "$RC_COMM" ]
      }

      # 完整命令行：/proc/<pid>/cmdline，NUL 分隔。
      # 同样用内建 read -d "" 按 NUL 切分，不 fork tr。
      read_cmdline() {
        local arg out=""
        while IFS= read -r -d "" arg; do
          out+="$arg "
        done 2>/dev/null < "/proc/$1/cmdline"
        RC_CMDLINE="''${out% }"
      }

      uid_of() { ps -o uid= -p "$1" 2>/dev/null | tr -d " "; }
      user_of() { ps -o user= -p "$1" 2>/dev/null | tr -d " "; }

      # 大小写不敏感的字面包含（关键词里带 * ? [ 都不会被当成通配符）
      ci_has() { [[ "''${1,,}" == *"''${2,,}"* ]]; }
      ci_eq() { [ "''${1,,}" = "''${2,,}" ]; }

      # 从 /proc/<pid>/cgroup 反推所属 unit
      read_unit() {
        local pid=$1 cg line path="" base
        RU_UNIT=""
        RU_SCOPE=""
        cg="/proc/$pid/cgroup"
        [ -r "$cg" ] || return 1
        while IFS= read -r line; do
          case "$line" in
            *name=systemd*) path="''${line#*name=systemd}" ;;
            0::*) path="''${line#0::}" ;;
            *) continue ;;
          esac
          path="''${path#:}"
          [ -n "$path" ] && break
        done < "$cg"
        [ -n "$path" ] || return 1
        base="''${path##*/}"
        case "$base" in
          *.service|*.socket|*.scope|*.mount|*.timer) ;;
          *) return 1 ;;
        esac
        RU_UNIT="$base"
        case "$path" in
          /user.slice*) RU_SCOPE="user" ;;
          *) RU_SCOPE="system" ;;
        esac
      }

      # 这些 unit 永远不要动：动了会掉会话 / 掉系统
      protected_unit() {
        case "$1" in
          init.scope|user@*.service) return 0 ;;
          dbus.service|dbus.socket|dbus-broker.service) return 0 ;;
          systemd-journald.*|systemd-logind.*|systemd-udevd.*) return 0 ;;
          systemd-*.socket) return 0 ;;
        esac
        return 1
      }

      has_unit() {
        local s=$1 n=$2 i
        for ((i = 0; i < ''${#UNIT_NAME[@]}; i++)); do
          if [ "''${UNIT_SCOPE[$i]}" = "$s" ] && [ "''${UNIT_NAME[$i]}" = "$n" ]; then
            return 0
          fi
        done
        return 1
      }

      alive() {
        read_stat "$1" || return 1
        [ "$RS_STATE" = "Z" ] && return 1
        return 0
      }

      # ---------------------------------------------------------------- 环境

      init_env() {
        PRIV=()
        if [ "$EUID" -ne 0 ]; then
          if [ -t 0 ]; then
            PRIV=(sudo)
          else
            PRIV=(sudo -n)
          fi
        fi

        USER_BUS_OK=0
        if [ "$EUID" -eq 0 ] && [ -n "''${SUDO_UID:-}" ] && [ -S "/run/user/''${SUDO_UID}/bus" ]; then
          UC=(sudo -u "#''${SUDO_UID}" env
              "XDG_RUNTIME_DIR=/run/user/''${SUDO_UID}"
              "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/''${SUDO_UID}/bus"
              systemctl --user)
          USER_BUS_OK=1
        elif [ -n "''${XDG_RUNTIME_DIR:-}" ] && [ -S "''${XDG_RUNTIME_DIR}/bus" ]; then
          UC=(systemctl --user)
          USER_BUS_OK=1
        else
          UC=(systemctl --user)
        fi
      }

      # 自己和所有祖先进程（shell、终端、sudo……）永不参与
      build_protected() {
        local p=$$
        PROTECTED=()
        while [ -n "$p" ] && [ "$p" != "0" ]; do
          PROTECTED+=("$p")
          read_stat "$p" || break
          p="$RS_PPID"
        done
      }

      is_protected() {
        local x
        for x in "''${PROTECTED[@]}"; do
          [ "$x" = "$1" ] && return 0
        done
        return 1
      }

      # ---------------------------------------------------------------- 采集

      collect_units() {
        local scope pat line name out
        UNIT_NAME=()
        UNIT_SCOPE=()

        for scope in system user; do
          if [ "$scope" = "user" ] && [ "$USER_BUS_OK" != 1 ]; then
            info "没有可用的 user D-Bus，跳过 user unit"
            continue
          fi

          for pat in "''${PATTERNS[@]}"; do
            if [ "$scope" = "user" ]; then
              out=$("''${UC[@]}" list-units --all --no-legend --plain --no-pager "*$pat*" 2>/dev/null) || out=""
            else
              out=$(systemctl list-units --all --no-legend --plain --no-pager "*$pat*" 2>/dev/null) || out=""
            fi
            [ -n "$out" ] || continue

            while IFS= read -r line; do
              name="''${line%% *}"
              [ -n "$name" ] || continue
              case "$name" in
                *.service|*.socket|*.scope) ;;
                *) continue ;;
              esac
              protected_unit "$name" && continue
              has_unit "$scope" "$name" || {
                UNIT_SCOPE+=("$scope")
                UNIT_NAME+=("$name")
              }
            done <<< "$out"
          done
        done
      }

      in_matched_unit() {
        local pid=$1 i
        read_unit "$pid" || return 1
        for ((i = 0; i < ''${#UNIT_NAME[@]}; i++)); do
          if [ "''${UNIT_NAME[$i]}" = "$RU_UNIT" ] && [ "''${UNIT_SCOPE[$i]}" = "$RU_SCOPE" ]; then
            return 0
          fi
        done
        return 1
      }

      scan_procs() {
        local path pid comm cmd state matched pat have_cmd

        T_PID=(); T_COMM=(); T_CMD=(); T_USER=(); T_STATE=(); T_UNIT=(); T_SCOPE=()
        ZOMBIES=(); UNKILLABLE=(); SKIPPED=()

        for path in /proc/[0-9]*; do
          pid="''${path#/proc/}"
          cmd=""
          have_cmd=0
          [ "$pid" = "1" ] && continue
          is_protected "$pid" && continue

          read_comm "$pid" || continue
          comm="$RC_COMM"
          [ -n "$comm" ] || continue
          read_stat "$pid" || continue
          state="$RS_STATE"

          matched=0
          for pat in "''${PATTERNS[@]}"; do
            if [ "$USE_EXACT" = 1 ]; then
              ci_eq "$comm" "$pat" && { matched=1; break; }
            else
              ci_has "$comm" "$pat" && { matched=1; break; }
            fi
          done

          if [ "$matched" = 0 ] && [ "$USE_FULL" = 1 ]; then
            read_cmdline "$pid"
            have_cmd=1
            for pat in "''${PATTERNS[@]}"; do
              ci_has "$RC_CMDLINE" "$pat" && { matched=1; break; }
            done
          fi

          if [ "$matched" = 0 ] && [ "$USE_UNITS" = 1 ] && [ "''${#UNIT_NAME[@]}" -gt 0 ]; then
            in_matched_unit "$pid" && matched=1
          fi

          [ "$matched" = 1 ] || continue

          if [ "$state" = "Z" ]; then
            ZOMBIES+=("$pid  $comm")
            continue
          fi

          if [ "$have_cmd" = 0 ]; then
            read_cmdline "$pid"
          fi
          cmd="$RC_CMDLINE"
          if [ -z "$cmd" ]; then
            UNKILLABLE+=("$pid  $comm  （内核线程或无命令行，收不到信号）")
            continue
          fi

          # 属于 init / user@ / dbus / journald 这类 unit 的进程默认不动
          TU="-"
          TS="-"
          if [ "$USE_UNITS" = 1 ] && read_unit "$pid"; then
            if [ "$FORCE" = 0 ] && protected_unit "$RU_UNIT"; then
              SKIPPED+=("$pid  $comm  （属于受保护的 unit：$RU_UNIT，加 -F 可强制）")
              continue
            fi
            TU="$RU_UNIT"
            TS="$RU_SCOPE"
          fi

          T_PID+=("$pid")
          T_COMM+=("$comm")
          T_CMD+=("''${cmd:0:110}")
          T_STATE+=("$state")
          T_USER+=("$(user_of "$pid")")
          T_UNIT+=("$TU")
          T_SCOPE+=("$TS")
        done
      }

      # ---------------------------------------------------------------- 展示

      print_plan() {
        local i

        if [ "''${#UNIT_NAME[@]}" -gt 0 ]; then
          printf "\n%s将停止 ''${#UNIT_NAME[@]} 个 systemd unit：%s\n" "$B" "$RST"
          for ((i = 0; i < ''${#UNIT_NAME[@]}; i++)); do
            printf "  %s[%s]%s %s\n" "$DIM" "''${UNIT_SCOPE[$i]}" "$RST" "''${UNIT_NAME[$i]}"
          done
        fi

        if [ "''${#T_PID[@]}" -gt 0 ]; then
          printf "\n%s将终止 ''${#T_PID[@]} 个进程：%s\n" "$B" "$RST"
          printf "  %-7s %-10s %-5s %-18s %s\n" "PID" "USER" "STATE" "NAME" "CMD"
          for ((i = 0; i < ''${#T_PID[@]}; i++)); do
            printf "  %-7s %-10s %-5s %-18s %s\n" \
              "''${T_PID[$i]}" "''${T_USER[$i]}" "''${T_STATE[$i]}" \
              "''${T_COMM[$i]}" "''${T_CMD[$i]}"
          done
        fi

        if [ "''${#ZOMBIES[@]}" -gt 0 ]; then
          printf "\n%s僵尸进程（杀不掉，要处理它的父进程）：%s\n" "$YEL" "$RST"
          for i in "''${ZOMBIES[@]}"; do printf "  %s\n" "$i"; done
        fi

        if [ "''${#UNKILLABLE[@]}" -gt 0 ]; then
          printf "\n%s无法用信号结束的对象：%s\n" "$YEL" "$RST"
          for i in "''${UNKILLABLE[@]}"; do printf "  %s\n" "$i"; done
        fi

        if [ "''${#SKIPPED[@]}" -gt 0 ]; then
          printf "\n%s已跳过（受保护，避免把会话/系统一起干掉）：%s\n" "$YEL" "$RST"
          for i in "''${SKIPPED[@]}"; do printf "  %s\n" "$i"; done
        fi
      }

      confirm() {
        local a
        if [ "$ASSUME_YES" = 1 ]; then
          return 0
        fi
        if [ ! -t 0 ]; then
          warn "标准输入不是终端，且没有 -y，已跳过执行。"
          return 1
        fi
        printf "\n%s执行以上操作？[y/N] %s" "$YEL" "$RST"
        read -r a || return 1
        case "$a" in
          y|Y|yes|YES|Yes) return 0 ;;
          *) return 1 ;;
        esac
      }

      # ---------------------------------------------------------------- 执行

      stop_units() {
        local i u s
        for ((i = 0; i < ''${#UNIT_NAME[@]}; i++)); do
          u="''${UNIT_NAME[$i]}"
          s="''${UNIT_SCOPE[$i]}"

          if [ "$DO_DISABLE" = 1 ]; then
            if [ "$s" = "user" ]; then
              "''${UC[@]}" disable "$u" >/dev/null 2>&1 || warn "disable $u 失败"
            else
              "''${PRIV[@]}" systemctl disable "$u" >/dev/null 2>&1 || warn "disable $u 失败"
            fi
          fi

          printf "  %s⟳%s stop [%s] %s\n" "$CYN" "$RST" "$s" "$u"
          if [ "$s" = "user" ]; then
            timeout 30 "''${UC[@]}" stop "$u" >/dev/null 2>&1 || info "stop $u 失败或超时"
          else
            timeout 30 "''${PRIV[@]}" systemctl stop "$u" >/dev/null 2>&1 || info "stop $u 失败或超时"
          fi
        done
      }

      try_kill() {
        local sig=$1 pid=$2 uid
        uid=$(uid_of "$pid")
        if [ "$EUID" -eq 0 ] || [ "''${uid:-x}" = "$EUID" ]; then
          kill -s "$sig" "$pid" 2>/dev/null && return 0
          return 1
        fi
        "''${PRIV[@]}" kill -s "$sig" "$pid" 2>/dev/null && return 0
        return 1
      }

      kill_phase() {
        local sig=$1 pid
        for pid in "''${T_PID[@]}"; do
          try_kill "$sig" "$pid" && continue
          # 进程可能刚好自己退了 / 已变僵尸，这不算失败
          alive "$pid" || continue
          PERM_FAIL=1
          warn "无法向 PID $pid 发送 SIG$sig（权限不足？）"
        done
        info "已发送 SIG$sig 给 ''${#T_PID[@]} 个进程"
      }

      alive_left() {
        local pid
        for pid in "''${T_PID[@]}"; do
          alive "$pid" && return 0
        done
        return 1
      }

      wait_until_dead() {
        local limit=$1 end any pid
        end=$(( SECONDS + limit ))
        while :; do
          any=0
          for pid in "''${T_PID[@]}"; do
            alive "$pid" && any=1
          done
          [ "$any" = 0 ] && return 0
          [ "$SECONDS" -ge "$end" ] && return 1
          sleep 0.2
        done
      }

      unit_active() {
        local scope=$1 u=$2
        if [ "$scope" = "user" ]; then
          "''${UC[@]}" is-active --quiet "$u" >/dev/null 2>&1
        else
          systemctl is-active --quiet "$u" >/dev/null 2>&1
        fi
      }

      # 兜底：unit 还 active 就直接对整个 cgroup 发 SIGKILL
      force_units() {
        local i u s
        [ "$USE_UNITS" = 1 ] || return 0
        for ((i = 0; i < ''${#UNIT_NAME[@]}; i++)); do
          u="''${UNIT_NAME[$i]}"
          s="''${UNIT_SCOPE[$i]}"
          unit_active "$s" "$u" || continue
          info "unit $u 仍在运行，对整个 cgroup 补 SIGKILL"
          if [ "$s" = "user" ]; then
            timeout 15 "''${UC[@]}" kill --kill-whom=all -s KILL "$u" >/dev/null 2>&1
            timeout 15 "''${UC[@]}" stop "$u" >/dev/null 2>&1
          else
            timeout 15 "''${PRIV[@]}" systemctl kill --kill-whom=all -s KILL "$u" >/dev/null 2>&1
            timeout 15 "''${PRIV[@]}" systemctl stop "$u" >/dev/null 2>&1
          fi
        done
      }

      # ---------------------------------------------------------------- 收尾

      report() {
        local i pid rc=0

        scan_procs

        if [ "''${#T_PID[@]}" -gt 0 ]; then
          rc=1
          printf "\n%s仍有 ''${#T_PID[@]} 个进程没结束：%s\n" "$RED" "$RST"
          for pid in "''${T_PID[@]}"; do
            read_stat "$pid"
            read_comm "$pid"
            printf "  PID %-7s [%s] %s\n" "$pid" "$RS_STATE" "$RC_COMM"
            case "$RS_STATE" in
              D)
                printf "    %s↳ D 状态（不可中断睡眠）：信号要等内核里的 I/O 返回才生效。%s\n" "$DIM" "$RST"
                printf "    %s  只能等它返回，或者 umount -l 解除卡住的挂载、重启。%s\n" "$DIM" "$RST"
                ;;
              Z)
                printf "    %s↳ 僵尸：进程已经死了，等父进程 wait()；杀它没有意义。%s\n" "$DIM" "$RST"
                ;;
              *)
                printf "    %s↳ 多半是权限不足，或者被父进程 / systemd 重新拉起来了。%s\n" "$DIM" "$RST"
                ;;
            esac
          done
          [ "$PERM_FAIL" = 1 ] && warn "有进程因权限不足没能发信号，可以重试：sudo k9 ..."
        fi

        if [ "$USE_UNITS" = 1 ]; then
          for ((i = 0; i < ''${#UNIT_NAME[@]}; i++)); do
            if unit_active "''${UNIT_SCOPE[$i]}" "''${UNIT_NAME[$i]}"; then
              rc=1
              printf "\n%sunit 仍处于 active：[%s] %s（可能被 Restart= 拉回，或还有别的依赖）%s\n" \
                "$RED" "''${UNIT_SCOPE[$i]}" "''${UNIT_NAME[$i]}" "$RST"
            fi
          done
        fi

        if [ "$rc" = 0 ]; then
          printf "\n%s✔ 清理完成。%s\n" "$GRN" "$RST"
        else
          printf "\n%s✘ 还有残留，原因见上。%s\n" "$RED" "$RST"
        fi
        return "$rc"
      }

      # ---------------------------------------------------------------- 入口

      parse_args() {
        local a
        while [ "$#" -gt 0 ]; do
          case "$1" in
            -h|--help)
              usage
              exit 0
              ;;
            -n|--dry-run|-l|--list)
              DRY_RUN=1
              shift
              ;;
            -y|--yes)
              ASSUME_YES=1
              shift
              ;;
            -f|--full)
              USE_FULL=1
              shift
              ;;
            -x|--exact)
              USE_EXACT=1
              shift
              ;;
            -k|--kill)
              FIRST_SIG="KILL"
              shift
              ;;
            -s|--signal)
              [ "$#" -ge 2 ] || die "$1 需要一个信号名"
              FIRST_SIG="$2"
              shift 2
              ;;
            -t|--timeout)
              [ "$#" -ge 2 ] || die "$1 需要一个秒数"
              WAIT_SECS="$2"
              shift 2
              ;;
            --no-escalate)
              ESCALATE=0
              shift
              ;;
            --no-units)
              USE_UNITS=0
              shift
              ;;
            -d|--disable)
              DO_DISABLE=1
              shift
              ;;
            -F|--force)
              FORCE=1
              shift
              ;;
            -v|--verbose)
              VERBOSE=1
              shift
              ;;
            --)
              shift
              while [ "$#" -gt 0 ]; do
                PATTERNS+=("$1")
                shift
              done
              ;;
            -*)
              die "未知选项：$1（-h 查看用法）"
              ;;
            *)
              PATTERNS+=("$1")
              shift
              ;;
          esac
        done

        a="''${#PATTERNS[@]}"
        [ "$a" -gt 0 ] || { usage >&2; exit 2; }

        case "$WAIT_SECS" in
          ""|*[!0-9]*) die "-t / --timeout 必须是秒数" ;;
        esac

        local pat
        for pat in "''${PATTERNS[@]}"; do
          [ -n "$pat" ] || die "关键词不能为空"
          if [ "$USE_EXACT" = 0 ] && [ "''${#pat}" -lt 2 ]; then
            die "关键词 “$pat” 太短，容易误杀；换个更具体的名字，或加 -x 精确匹配"
          fi
        done
      }

      main() {
        parse_args "$@"
        init_env
        build_protected
        collect_units
        scan_procs

        if [ "''${#UNIT_NAME[@]}" -eq 0 ] && [ "''${#T_PID[@]}" -eq 0 ]; then
          if [ "''${#SKIPPED[@]}" -gt 0 ] || [ "''${#ZOMBIES[@]}" -gt 0 ] || [ "''${#UNKILLABLE[@]}" -gt 0 ]; then
            print_plan
            printf "\n%s没有可处理的对象：匹配到的东西都被跳过了。%s\n" "$YEL" "$RST"
            printf "  确实要动受保护的 unit / 进程，加 -F（谨慎：可能掉会话或掉系统）\n" >&2
            exit 1
          fi
          warn "没有匹配到任何进程或 unit：''${PATTERNS[*]}"
          printf "  试试：k9 -f <关键词>      按完整命令行匹配\n" >&2
          printf "        sudo k9 <关键词>    别的用户的进程\n" >&2
          printf "        systemctl list-units | grep -i <关键词>\n" >&2
          exit 1
        fi

        print_plan

        if [ "$DRY_RUN" = 1 ]; then
          printf "\n%s（dry-run，未执行任何操作）%s\n" "$DIM" "$RST"
          exit 0
        fi

        if ! confirm; then
          printf "\n已取消。\n"
          exit 0
        fi

        printf "\n%s开始清理……%s\n" "$B" "$RST"

        # 1) 先停 unit：整 cgroup 一起走，也不会被 Restart= 立刻拉回
        if [ "$USE_UNITS" = 1 ] && [ "''${#UNIT_NAME[@]}" -gt 0 ]; then
          stop_units
          sleep 0.5
        fi

        # 2) 重新采集：unit 停掉之后还在的，才是需要逐个发信号的
        scan_procs

        if [ "''${#T_PID[@]}" -gt 0 ]; then
          kill_phase "$FIRST_SIG"
          wait_until_dead "$WAIT_SECS"

          if [ "$ESCALATE" = 1 ] && [ "$FIRST_SIG" != "KILL" ] && alive_left; then
            info "还有进程活着，升级到 SIGKILL"
            kill_phase "KILL"
            wait_until_dead "$WAIT_SECS"
          fi
        fi

        # 3) 兜底：unit 还 active 就整组 SIGKILL
        force_units

        # 4) 收尾检查
        if report; then
          exit 0
        else
          exit 3
        fi
      }

      main "$@"
    '')
  ];
}
