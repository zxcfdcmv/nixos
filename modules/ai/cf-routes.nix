# cf-ai-routes：用 Cloudflare REST API 管理 AI Gateway 动态路由。
#
# 仪表板的可视化构建器不支持直接编辑 JSON，所以路由定义放在
# modules/ai/cf-models.nix 里，由本脚本生成请求体并应用。
#
# token：优先 $CLOUDFLARE_API_TOKEN，否则从 rbw 的 cloudflare-aig 读取
# （该条目同时具备 AI Gateway 调用和 AI Gateway Write 权限）。
{ config, pkgs, lib, userSettings, ... }:
let
  cf = import ./cf-models.nix { inherit lib; };
  routesFile = pkgs.writeText "cf-ai-gateway-routes.json" (builtins.toJSON cf.routeDefinitions);
  defaultRoutes = lib.concatStringsSep " " (builtins.attrNames cf.routeDefinitions);

  cfRoutes = pkgs.writeShellApplication {
    name = "cf-ai-routes";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      jq
      rbw
    ];
    text = ''
      ACCOUNT_ID="${userSettings.account_id}"
      GATEWAY_ID="${userSettings.gateway}"
      ROUTES_JSON="${routesFile}"
      API="https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/ai-gateway/gateways/$GATEWAY_ID/routes"
      GATEWAY_BASE="https://gateway.ai.cloudflare.com/v1/$ACCOUNT_ID/$GATEWAY_ID"
      read -r -a DEFAULT_ROUTES <<< "${defaultRoutes}"

      usage() {
        cat <<'EOF'
      用法: cf-ai-routes <命令> [路由名...]

      路由名: free / vision / long（省略时对全部路由执行）

      命令:
        list            列出远端路由
        show <路由>     查看远端某条路由的 JSON
        diff [路由...]  比较本地定义与远端，打印漂移
        apply [路由...] 创建或更新路由（存在则 PATCH，PATCH 不可用时删除重建）
        test [路由...]  发一条最小请求，打印 cf-aig-step / cf-aig-model
        env             打印账号、网关和本地路由文件位置

      示例:
        cf-ai-routes diff
        cf-ai-routes apply
        cf-ai-routes test free

      注意: apply / test 需要能读取 rbw 条目 cloudflare-aig，
            或已设置 CLOUDFLARE_API_TOKEN。
      EOF
      }

      die() {
        echo "cf-ai-routes: $*" >&2
        exit 1
      }

      resolve_token() {
        if [ -n "''${CLOUDFLARE_API_TOKEN:-}" ]; then
          printf '%s' "$CLOUDFLARE_API_TOKEN"
          return 0
        fi
        rbw get cloudflare-aig 2>/dev/null \
          || die "拿不到 Cloudflare API token（rbw 条目 cloudflare-aig）"
      }

      TOKEN="$(resolve_token)"
      AUTH=(-H "Authorization: Bearer $TOKEN")

      api_get() {
        curl -fsS "$1" "''${AUTH[@]}"
      }

      route_list() {
        api_get "$API" | jq -c '(.result // .data.routes // [])'
      }

      route_json() {
        route_list | jq -c --arg n "$1" '.[] | select(.name == $n)'
      }

      route_id() {
        route_json "$1" | jq -r '.id // empty'
      }

      route_elements() {
        local id
        id="$(route_id "$1")"
        [ -n "$id" ] || return 0
        api_get "$API/$id" \
          | jq -S '.result.version.data // .result.elements // empty'
      }

      check_response() {
        local response="$1"
        local action="$2"
        if printf '%s' "$response" | jq -e '.success == true' >/dev/null 2>&1; then
          return 0
        fi
        echo "失败: $action" >&2
        printf '%s' "$response" \
          | jq -r '.errors[]? | "  \(.code): \(.message)"' >&2 2>/dev/null \
          || true
        return 1
      }

      post_route() {
        local body="$1"
        local response
        response="$(curl -sS -X POST "$API" "''${AUTH[@]}" \
          -H "Content-Type: application/json" --data "$body")" \
          || die "POST $API 失败"
        check_response "$response" "创建路由"
      }

      patch_route() {
        local id="$1"
        local body="$2"
        local response
        response="$(curl -sS -X PATCH "$API/$id" "''${AUTH[@]}" \
          -H "Content-Type: application/json" --data "$body")" \
          || return 1
        check_response "$response" "更新路由"
      }

      apply_route() {
        local name="$1"
        local body
        local id
        body="$(jq -c --arg n "$name" \
          '.[$n] | {name: .name, elements: .elements}' "$ROUTES_JSON")"
        [ "$body" != "null" ] || die "未知路由: $name（可选: ''${DEFAULT_ROUTES[*]}）"

        id="$(route_id "$name")"
        if [ -z "$id" ]; then
          post_route "$body"
          echo "已创建 dynamic/$name"
        elif patch_route "$id" "$body"; then
          echo "已更新 dynamic/$name"
        else
          echo "PATCH 不可用，改为删除后重建 dynamic/$name" >&2
          curl -sS -X DELETE "$API/$id" "''${AUTH[@]}" >/dev/null \
            || die "删除旧路由失败"
          post_route "$body"
          echo "已重建 dynamic/$name"
        fi
      }

      resolve_names() {
        if [ "$#" -eq 0 ]; then
          printf '%s\n' "''${DEFAULT_ROUTES[@]}"
        else
          printf '%s\n' "$@"
        fi
      }

      cmd_apply() {
        local name
        while IFS= read -r name; do
          apply_route "$name"
        done < <(resolve_names "$@")
      }

      cmd_diff() {
        local name
        local remote
        local local_json
        while IFS= read -r name; do
          remote="$(route_elements "$name")"
          local_json="$(jq -S --arg n "$name" '.[$n].elements' "$ROUTES_JSON")"
          if [ -z "$remote" ]; then
            echo "缺失 dynamic/$name（远端不存在）"
          elif [ "$remote" = "$local_json" ]; then
            echo "一致 dynamic/$name"
          else
            echo "漂移 dynamic/$name"
            diff -u <(printf '%s\n' "$local_json") <(printf '%s\n' "$remote") || true
          fi
        done < <(resolve_names "$@")
      }

      cmd_test() {
        local name
        local header
        local body
        local code
        while IFS= read -r name; do
          header="$(mktemp)"
          body="$(mktemp)"
          code="$(curl -sS -o "$body" -D "$header" -w '%{http_code}' \
            "$GATEWAY_BASE/compat/chat/completions" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            --data "{\"model\":\"dynamic/$name\",\"messages\":[{\"role\":\"user\",\"content\":\"只回复 ok\"}],\"max_tokens\":32}" \
            2>/dev/null || true)"
          echo "== dynamic/$name  HTTP $code"
          grep -i '^cf-aig-' "$header" | tr -d '\r' || true
          jq -r '.choices[0].message.content // .error.message // empty' "$body" \
            2>/dev/null | head -c 300 || true
          echo
          rm -f "$header" "$body"
        done < <(resolve_names "$@")
      }

      cmd_show() {
        local name="''${1:?用法: cf-ai-routes show <free|vision|long>}"
        local id
        id="$(route_id "$name")"
        if [ -z "$id" ]; then
          echo "远端没有 dynamic/$name"
          exit 1
        fi
        api_get "$API/$id" | jq '.result'
      }

      command="''${1:-list}"
      if [ "$#" -gt 0 ]; then
        shift
      fi

      case "$command" in
        list)
          route_list | jq '.'
          ;;
        show)
          cmd_show "$@"
          ;;
        diff)
          cmd_diff "$@"
          ;;
        apply)
          cmd_apply "$@"
          ;;
        test)
          cmd_test "$@"
          ;;
        env)
          echo "account: $ACCOUNT_ID"
          echo "gateway: $GATEWAY_ID"
          echo "routes file: $ROUTES_JSON"
          echo "default routes: ''${DEFAULT_ROUTES[*]}"
          ;;
        help | -h | --help)
          usage
          ;;
        *)
          usage
          exit 1
          ;;
      esac
    '';
    meta.description = "管理 Cloudflare AI Gateway 动态路由（定义来自 modules/ai/cf-models.nix）";
  };
in
{
  home.packages = [ cfRoutes ];
}
