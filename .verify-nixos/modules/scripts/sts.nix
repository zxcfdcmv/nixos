# modules/scripts/jts.nix
{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "sts" ''
      set -u

      readonly PROG="sts"

      usage() {
        cat <<'EOF'
用法：
  sts <名称或关键词>
      自动范围：优先当前用户 unit，再查系统 unit。
      先精确匹配；没有精确结果时再模糊匹配。

  sts --user <名称或关键词>
      仅查询当前用户的 systemd --user unit。

  sts --system <名称或关键词>
      仅查询系统级 systemd unit；查看时按需调用 sudo。

  sts --user <用户名> <完整或简写 unit 名>
      查询指定用户的 user unit。
      例如：sts --user alice syncthing
            sts --user alice my-daemon.socket

支持的 unit：
  service、socket、timer、path、target、mount、scope

示例：
  sts syncthing
  sts pipe
  sts docker.socket
  sts --user waybar
  sts --system docker
  sts --system network
  sts --user alice my-daemon.socket
EOF
      }

      die() {
        echo "错误：$*" >&2
        exit 2
      }

      has_user_bus() {
        [ -n "''${XDG_RUNTIME_DIR:-}" ] &&
        [ -S "''${XDG_RUNTIME_DIR}/bus" ]
      }

      # 输入带后缀时，直接作为完整 unit 名使用。
      # 无后缀时，依次尝试常用 unit 类型。
      exact_unit_candidates() {
        local input="$1"

        case "$input" in
          *.*)
            printf '%s\n' "$input"
            ;;
          *)
            printf '%s.service\n' "$input"
            printf '%s.socket\n' "$input"
            printf '%s.timer\n' "$input"
            printf '%s.path\n' "$input"
            printf '%s.target\n' "$input"
            printf '%s.mount\n' "$input"
            printf '%s.scope\n' "$input"
            ;;
        esac
      }

      user_unit_exists() {
        local unit="$1"

        has_user_bus || return 1

        systemctl --user show "$unit" \
          --property=LoadState \
          --value \
          2>/dev/null |
          grep -qxv 'not-found'
      }

      system_unit_exists() {
        local unit="$1"

        systemctl show "$unit" \
          --property=LoadState \
          --value \
          2>/dev/null |
          grep -qxv 'not-found'
      }

      show_current_user_unit() {
        local unit="$1"

        if ! has_user_bus; then
          die "当前 shell 未连接到 systemd 用户总线。

请在正常的桌面/登录会话中执行。

若是 SSH、脚本、tmux server 或其他非标准环境，可尝试：
  export XDG_RUNTIME_DIR=/run/user/\$(id -u)
然后再运行：
  sts --user $unit"
        fi

        echo "==> 用户 unit：$USER / $unit"
        exec systemctl --user status "$unit"
      }

      show_system_unit() {
        local unit="$1"

        echo "==> 系统 unit：$unit"

        if [ "$EUID" -eq 0 ]; then
          exec systemctl status "$unit"
        else
          exec sudo systemctl status "$unit"
        fi
      }

      other_user_runtime_dir() {
        local target_user="$1"
        local uid

        uid="$(id -u "$target_user" 2>/dev/null)" ||
          die "用户不存在：$target_user"

        printf '/run/user/%s\n' "$uid"
      }

      other_user_unit_exists() {
        local target_user="$1"
        local runtime_dir="$2"
        local unit="$3"

        sudo -u "$target_user" \
          XDG_RUNTIME_DIR="$runtime_dir" \
          DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime_dir/bus" \
          systemctl --user show "$unit" \
            --property=LoadState \
            --value \
            2>/dev/null |
          grep -qxv 'not-found'
      }

      show_other_user_unit() {
        local target_user="$1"
        local runtime_dir="$2"
        local unit="$3"

        echo "==> 用户 unit：$target_user / $unit"

        exec sudo -u "$target_user" \
          XDG_RUNTIME_DIR="$runtime_dir" \
          DBUS_SESSION_BUS_ADDRESS="unix:path=$runtime_dir/bus" \
          systemctl --user status "$unit"
      }

      # 输出：scope<TAB>unit
      # scope 只可能是 user 或 system。
      find_exact_units() {
        local mode="$1"
        local input="$2"
        local unit

        while IFS= read -r unit; do
          case "$mode" in
            user)
              if user_unit_exists "$unit"; then
                printf 'user\t%s\n' "$unit"
              fi
              ;;
            system)
              if system_unit_exists "$unit"; then
                printf 'system\t%s\n' "$unit"
              fi
              ;;
            auto)
              if user_unit_exists "$unit"; then
                printf 'user\t%s\n' "$unit"
              fi

              if system_unit_exists "$unit"; then
                printf 'system\t%s\n' "$unit"
              fi
              ;;
            *)
              die "未知查询范围：$mode"
              ;;
          esac
        done < <(exact_unit_candidates "$input")
      }

      # 搜索当前用户中已加载与已安装的 unit。
      # 输出：user<TAB>unit
      search_user_units() {
        local query="$1"

        has_user_bus || return 0

        {
          systemctl --user list-units \
            --all \
            --no-legend \
            --no-pager \
            --plain \
            "*$query*" 2>/dev/null |
            awk '{ print $1 }'

          systemctl --user list-unit-files \
            --no-legend \
            --no-pager \
            --plain \
            "*$query*" 2>/dev/null |
            awk '{ print $1 }'
        } |
          awk '
            $1 ~ /\.(service|socket|timer|path|target|mount|scope)$/ {
              print "user\t" $1
            }
          ' |
          sort -u
      }

      # 搜索系统范围中已加载与已安装的 unit。
      # 输出：system<TAB>unit
      search_system_units() {
        local query="$1"

        {
          systemctl list-units \
            --all \
            --no-legend \
            --no-pager \
            --plain \
            "*$query*" 2>/dev/null |
            awk '{ print $1 }'

          systemctl list-unit-files \
            --no-legend \
            --no-pager \
            --plain \
            "*$query*" 2>/dev/null |
            awk '{ print $1 }'
        } |
          awk '
            $1 ~ /\.(service|socket|timer|path|target|mount|scope)$/ {
              print "system\t" $1
            }
          ' |
          sort -u
      }

      # 输入多条 scope<TAB>unit：
      # - 只有一条时直接 status
      # - 多条时要求用户输入编号
      choose_and_show() {
        local matches="$1"
        local scope unit choice
        local -a scopes units
        local count i

        while IFS=$'\t' read -r scope unit; do
          [ -n "$scope" ] || continue
          scopes+=("$scope")
          units+=("$unit")
        done <<EOF
$matches
EOF

        count="''${#units[@]}"

        [ "$count" -gt 0 ] || return 1

        if [ "$count" -eq 1 ]; then
          if [ "''${scopes[0]}" = "user" ]; then
            show_current_user_unit "''${units[0]}"
          else
            show_system_unit "''${units[0]}"
          fi
        fi

        echo "找到多个匹配："
        echo

        i=0
        while [ "$i" -lt "$count" ]; do
          printf '  %d) [%s] %s\n' \
            "$((i + 1))" \
            "''${scopes[$i]}" \
            "''${units[$i]}"
          i="$((i + 1))"
        done

        echo
        printf '选择 unit 编号（q 退出）：' >&2
        read -r choice || exit 0

        case "$choice" in
          q|Q|"")
            exit 0
            ;;
          *[!0-9]*)
            die "请输入有效编号。"
            ;;
        esac

        [ "$choice" -ge 1 ] 2>/dev/null &&
          [ "$choice" -le "$count" ] 2>/dev/null ||
          die "编号超出范围。"

        i="$((choice - 1))"

        if [ "''${scopes[$i]}" = "user" ]; then
          show_current_user_unit "''${units[$i]}"
        else
          show_system_unit "''${units[$i]}"
        fi
      }

      search_and_show() {
        local mode="$1"
        local query="$2"
        local matches

        case "$mode" in
          user)
            matches="$(search_user_units "$query")"
            ;;
          system)
            matches="$(search_system_units "$query")"
            ;;
          auto)
            matches="$(
              {
                search_user_units "$query"
                search_system_units "$query"
              } | sort -u
            )"
            ;;
          *)
            die "未知查询范围：$mode"
            ;;
        esac

        if [ -z "$matches" ]; then
          echo "未找到名称包含 '$query' 的 unit。" >&2
          echo >&2
          echo "提示：" >&2
          echo "  sts --user <关键词>     仅查当前用户 unit" >&2
          echo "  sts --system <关键词>   仅查系统 unit" >&2
          exit 4
        fi

        choose_and_show "$matches"
      }

      find_other_user_exact_units() {
        local target_user="$1"
        local runtime_dir="$2"
        local input="$3"
        local unit

        while IFS= read -r unit; do
          if other_user_unit_exists "$target_user" "$runtime_dir" "$unit"; then
            printf '%s\n' "$unit"
          fi
        done < <(exact_unit_candidates "$input")
      }

      handle_other_user() {
        local target_user="$1"
        local input="$2"
        local runtime_dir matches count selected

        runtime_dir="$(other_user_runtime_dir "$target_user")"

        [ -d "$runtime_dir" ] ||
          die "用户 $target_user 当前没有运行中的 user manager（找不到 $runtime_dir）。

请让该用户登录，或执行：
  sudo loginctl enable-linger $target_user"

        matches="$(find_other_user_exact_units "$target_user" "$runtime_dir" "$input")"

        if [ -z "$matches" ]; then
          die "在用户 $target_user 的 user manager 中找不到精确 unit：$input

请指定完整名称，例如：
  $PROG --user $target_user foo.socket"
        fi

        count="$(printf '%s\n' "$matches" | wc -l)"

        if [ "$count" -gt 1 ]; then
          echo "用户 $target_user 存在多个同名 unit：" >&2
          printf '%s\n' "$matches" | nl -ba >&2
          die "请指定 unit 后缀，例如：$PROG --user $target_user foo.socket"
        fi

        selected="$matches"
        show_other_user_unit "$target_user" "$runtime_dir" "$selected"
      }

      main() {
        local mode="auto"
        local input exact_matches
        local target_user=""

        case "''${1:-}" in
          -h|--help)
            usage
            exit 0
            ;;
          --user|-u)
            mode="user"
            shift
            ;;
          --system|-s)
            mode="system"
            shift
            ;;
        esac

        [ "$#" -ge 1 ] || {
          usage >&2
          exit 2
        }

        # 唯一的两个位置参数形式：
        # sts --user <用户名> <unit>
        if [ "$mode" = "user" ] && [ "$#" -eq 2 ]; then
          target_user="$1"
          input="$2"
          handle_other_user "$target_user" "$input"
        fi

        [ "$#" -eq 1 ] ||
          die "参数数量不正确。运行 '$PROG --help' 查看用法。"

        input="$1"

        # 先做精确匹配：
        # foo -> foo.service / foo.socket / foo.timer / ...
        # foo.socket -> foo.socket
        exact_matches="$(find_exact_units "$mode" "$input" | sort -u)"

        if [ -n "$exact_matches" ]; then
          choose_and_show "$exact_matches"
        fi

        # 无精确候选后，进行名称包含匹配：
        # pipe -> *pipe*
        search_and_show "$mode" "$input"
      }

      main "$@"
    '')
  ];
}
