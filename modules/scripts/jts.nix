# modules/scripts/jts.nix
{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "jts" ''
      set -u

      readonly PROG="jts"

      usage() {
        cat <<'EOF'
用法：
  jts <名称或关键词>
      自动范围：当前用户 unit + 系统 unit。
      先精确匹配；未命中后进行模糊匹配。

  jts --user <名称或关键词>
      仅查看当前用户 systemd --user unit 的日志。

  jts --system <名称或关键词>
      仅查看系统级 unit 的日志；权限不足时自动 sudo。

  jts -f <名称或关键词>
  jts --follow <名称或关键词>
      持续跟随日志，等价于 journalctl -f。

  jts -n <行数> <名称或关键词>
  jts --lines <行数> <名称或关键词>
      显示末尾 N 行；默认 100 行。

  jts --since <时间> <名称或关键词>
  jts --until <时间> <名称或关键词>
      传递 journalctl 的时间条件。
      示例：jts --since "today" docker
            jts --since "1 hour ago" --follow docker

支持的 unit：
  service、socket、timer、path、target、mount、scope

示例：
  jts nginx
  jts docker.socket
  jts pipe
  jts --user waybar
  jts --system NetworkManager
  jts -f pipewire
  jts -n 300 --system docker
  jts --since "today" --user waybar
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

      run_user_journal() {
        local unit="$1"

        echo "==> 用户日志：$USER / $unit" >&2

        exec journalctl \
          --user \
          --unit="$unit" \
          --no-pager \
          --output=short-iso \
          "''${journal_args[@]}"
      }

      run_system_journal() {
        local unit="$1"

        echo "==> 系统日志：$unit" >&2

        if [ "$EUID" -eq 0 ]; then
          exec journalctl \
            --system \
            --unit="$unit" \
            --no-pager \
            --output=short-iso \
            "''${journal_args[@]}"
        else
          exec sudo journalctl \
            --system \
            --unit="$unit" \
            --no-pager \
            --output=short-iso \
            "''${journal_args[@]}"
        fi
      }

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
            run_user_journal "''${units[0]}"
          else
            run_system_journal "''${units[0]}"
          fi
        fi

        echo "找到多个匹配：" >&2
        echo >&2

        i=0
        while [ "$i" -lt "$count" ]; do
          printf '  %d) [%s] %s\n' \
            "$((i + 1))" \
            "''${scopes[$i]}" \
            "''${units[$i]}" >&2
          i="$((i + 1))"
        done

        echo >&2
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
          run_user_journal "''${units[$i]}"
        else
          run_system_journal "''${units[$i]}"
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
          die "未找到名称包含 '$query' 的 unit。"
        fi

        choose_and_show "$matches"
      }

      main() {
        local mode="auto"
        local input=""
        local exact_matches=""
        local follow="false"
        local lines="100"

        journal_args=()

        while [ "$#" -gt 0 ]; do
          case "$1" in
            -h|--help)
              usage
              exit 0
              ;;
            --user|-u)
              [ "$mode" = "auto" ] || die "--user 与 --system 不能同时使用。"
              mode="user"
              shift
              ;;
            --system|-s)
              [ "$mode" = "auto" ] || die "--user 与 --system 不能同时使用。"
              mode="system"
              shift
              ;;
            -f|--follow)
              follow="true"
              shift
              ;;
            -n|--lines)
              [ "$#" -ge 2 ] || die "$1 需要一个行数参数。"
              lines="$2"
              shift 2
              ;;
            --since|--until)
              [ "$#" -ge 2 ] || die "$1 需要一个时间参数。"
              journal_args+=("$1" "$2")
              shift 2
              ;;
            --)
              shift
              break
              ;;
            -*)
              die "未知选项：$1"
              ;;
            *)
              if [ -n "$input" ]; then
                die "只能指定一个 unit 名称或关键词：已收到 '$input' 和 '$1'。"
              fi
              input="$1"
              shift
              ;;
          esac
        done

        [ -n "$input" ] || {
          usage >&2
          exit 2
        }

        case "$lines" in
          *[!0-9]*|"")
            die "-n / --lines 的值必须是非负整数。"
            ;;
        esac

        journal_args+=("--lines=$lines")

        if [ "$follow" = "true" ]; then
          journal_args+=("--follow")
        fi

        # 先按完整 unit 名精确匹配：
        # docker -> docker.service、docker.socket、docker.timer...
        # docker.socket -> docker.socket
        exact_matches="$(find_exact_units "$mode" "$input" | sort -u)"

        if [ -n "$exact_matches" ]; then
          choose_and_show "$exact_matches"
        fi

        # 精确没有找到时，做名称包含匹配：
        # pipe -> *pipe*
        search_and_show "$mode" "$input"
      }

      main "$@"
    '')
  ];
}
