# OpenCode 提供商配置。
#
# 模型列表与 modules/ai/ai.nix 里 Zed 的 language_models 保持一致：
# 都走 Cloudflare AI Gateway，分别是 OpenAI 兼容入口和 OpenRouter 入口。
# 密钥沿用 zed-ai / dsh-ai 的做法，从 rbw 读取后在启动时注入。
{ config, pkgs, lib, userSettings, ... }:

let
  # 模型 / 动态路由的单一事实来源，和 ai.nix、dsh.nix 共用。
  cf = import ./cf-models.nix { inherit lib; };
  gatewayBase = "https://gateway.ai.cloudflare.com/v1/${userSettings.account_id}/${userSettings.gateway}";

  # Zed 的 max_tokens 是上下文窗口，这里对应 OpenCode 的 limit.context。
  # 输出上限 Zed 没有逐模型配置，和 dsh 一样统一用 32768 兜底。
  mkModel = { name, context, vision ? false, ... }:
    {
      inherit name;
      limit = {
        inherit context;
        output = 32768;
      };
      capabilities = {
        tools = true;
        input = if vision then [ "text" "image" ] else [ "text" ];
        output = [ "text" ];
      };
    };

  cfModels = cf.models;

  cfModelSet = builtins.listToAttrs (map (model: {
    name = model.id;
    value = (mkModel model) // { modelID = model.id; };
  }) cfModels);

  openrouterModelSet = {
    # 选择器是 openrouter/free，发给网关的模型名仍是 openrouter/free。
    free = (mkModel { name = "OpenRouter Free Router"; context = 131072; }) // {
      modelID = "openrouter/free";
    };
  };

  # OpenCode 2 的模型声明格式：能力/推理写在 capabilities 里，
  # reasoning.effort 会自动生成对应的 #variant（low/high/max 等）。
  # 旧版的 reasoning/modalities/对象形式 variants 在 v2 里是非法字段，
  # 会导致整个 provider 被判定为 malformed 而跳过。
  mkSub2apiModel = { name, context, output, input ? [ "text" ], effort ? null }:
    {
      inherit name;
      limit = { inherit context output; };
      capabilities = {
        tools = true;
        inherit input;
        output = [ "text" ];
        reasoning = { supported = true; } // lib.optionalAttrs (effort != null) {
          inherit effort;
        };
      };
    };

  # OpenCode 2 的模型请求由后台 service 执行，CLI 里 export 的变量到不了
  # service。这里在密钥或 home-manager 配置层变化时同步进 service 并重启，
  # 和 dsh-ai 的注入方式一致。
  opencodeEnv = pkgs.writeShellScript "opencode-env" ''
    # Zed 从图形会话启动时不一定继承 hm-session-vars.sh；显式指向
    # home-manager 生成的声明式配置层，保证模型列表总能被加载。
    export OPENCODE_CONFIG="${config.xdg.configHome}/opencode/home-manager.json"

    gatewayKey="$(${lib.getExe pkgs.rbw} get cloudflare-aig 2>/dev/null || true)"
    if [ -n "$gatewayKey" ]; then
      export CF_GATEWAY_API_KEY="$gatewayKey"
      export OPENROUTER_API_KEY="$gatewayKey"
    fi

    sub2apiKey="$(${lib.getExe pkgs.rbw} get sub2api 2>/dev/null || true)"
    if [ -n "$sub2apiKey" ]; then
      export SUB2API_API_KEY="$sub2apiKey"
    fi

    restart=0
    syncServiceEnv() {
      name="$1"
      value="$2"
      [ -n "$value" ] || return 0
      current="$(${lib.getExe pkgs.opencode} service get env "$name" 2>/dev/null || true)"
      if [ "$current" != "$value" ]; then
        ${lib.getExe pkgs.opencode} service set env "$name" "$value" >/dev/null 2>&1 || true
        restart=1
      fi
    }

    syncServiceEnv CF_GATEWAY_API_KEY "''${CF_GATEWAY_API_KEY:-}"
    syncServiceEnv OPENROUTER_API_KEY "''${OPENROUTER_API_KEY:-}"
    syncServiceEnv SUB2API_API_KEY "''${SUB2API_API_KEY:-}"
    syncServiceEnv OPENCODE_CONFIG "''${OPENCODE_CONFIG:-}"

    # 和 OPENCODE_CONFIG 同理：CLI 层直接读 home-manager 生成的文件，不依赖
    # hm-session-vars.sh 是否生效（从 Zed、快捷方式、旧 shell 里启动时经常没有，
    # 结果就是插件列表一直停在服务里那份旧值）。
    cliLayer="${config.xdg.configHome}/opencode/home-manager-cli.json"
    if [ -z "''${OPENCODE_CLI_CONFIG_CONTENT:-}" ] && [ -r "$cliLayer" ]; then
      OPENCODE_CLI_CONFIG_CONTENT="$(cat "$cliLayer")"
      export OPENCODE_CLI_CONFIG_CONTENT
    fi
    syncServiceEnv OPENCODE_CLI_CONFIG_CONTENT "''${OPENCODE_CLI_CONFIG_CONTENT:-}"

    if [ "$restart" = 1 ]; then
      ${lib.getExe pkgs.opencode} service restart >/dev/null 2>&1 || true
    fi

    :
  '';

  # 保留原包的版本和 passthru，避免 programs.opencode 把它当成 OpenCode 1。
  opencodeWrapped = pkgs.symlinkJoin {
    name = "opencode-${pkgs.opencode.version}-wrapped";
    paths = [ pkgs.opencode ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/opencode --run 'source ${opencodeEnv}'
    '';
    passthru = pkgs.opencode.passthru or { };
    meta = pkgs.opencode.meta;
  };
in
{

  home.packages = with pkgs; [ snip ];

  # OpenCode 全局指令，由 ~/.config/opencode/AGENTS.md 自动加载。
  xdg.configFile."opencode/AGENTS.md".text = ''
    # 文档处理
    - docx / xlsx / pptx 的读取、修改、转换：优先用 docforge 的 MCP 工具。
    - PDF / HTML / EPUB → Markdown：用 markitdown。
    - Markdown → docx / pptx：用 pandoc；不用转 PDF，我自己转。

    # 系统边界
    - 不要运行 nixos-rebuild；改完把命令告诉我。
    - 不要手工编辑 flake.lock；用 nix flake lock。
    - 本地缺工具时用临时环境：
      nix-shell -p <包名> --run '<命令>'
      必须带 --run，不能进入交互 shell。
    - 禁止 pip / npm / nix-env / nix profile 安装任何东西；遇到只有 pip/npm
      才有的包，停下来告诉我包名和用途，由我决定是否加进 Nix 配置。
    - nix-shell / nix eval / nix build 需要联网拉依赖时，若 60 秒内没有明显
      进展或下载极慢，直接终止并报告，不要反复重试；预计很慢的操作先问我。

    # shell
    - 非交互：不用 vim / less / man，不用交互式 git；git 用 --no-pager 和 -m。
    - 需要 root 时用 sudo -n，失败就停下报告。
  '';

  # opencode 本体由 programs.opencode 安装，ai.nix 里不要再重复列一遍。
  programs.opencode = {
    enable = true;
    package = opencodeWrapped;
    enableMcpIntegration = true;
    mutableSettings = true;

    cli = {
      theme = {
        name = "system";
        mode = "system";
      };
      plugins = [
        "@madsoftwaredev/opencode-sidebar-resize"
        {
          package = "@cardinal4/opencode-fold-diffs";
          options = {
            min_lines = 0;
            lines = 0;
            bash = true;
            bash_lines = 1;
            stats = false;
          };
        }
      ];
    };

    settings = {
      plugin = [
        "oc-go-multi-auth"
        "@tarquinen/opencode-dcp"
        "opencode-snip"
        "opencode-footprints"
        "@bojackduy/opencode-telescope"
      ];
      providers = {
        cf_gateway = {
          name = "Cloudflare AI Gateway";
          env = [ "CF_GATEWAY_API_KEY" ];
          package = "@opencode/ai/providers/openai-compatible";
          # 网关后面的模型大多是 DeepSeek/GLM 一类，统一按 max_tokens 发送。
          compatibility = {
            maxTokensField = "max_tokens";
          };
          settings = {
            baseURL = "${gatewayBase}/compat";
            apiKey = "{env:CF_GATEWAY_API_KEY}";
          };
          models = cfModelSet;
        };

        openrouter = {
          name = "OpenRouter (Cloudflare AI Gateway)";
          env = [ "OPENROUTER_API_KEY" ];
          # 走 OpenRouter 网关时保留原生 OpenRouter 运行时。
          package = "@opencode/ai/providers/openrouter";
          compatibility = {
            maxTokensField = "max_tokens";
          };
          settings = {
            baseURL = "${gatewayBase}/openrouter";
            apiKey = "{env:OPENROUTER_API_KEY}";
          };
          models = openrouterModelSet;
        };

        # 方案 B：非官方订阅专线（sub2api），独立于 Cloudflare AI Gateway。
        # API Key 从 rbw 条目 "sub2api" 读取并注入为 SUB2API_API_KEY。
        sub2api = {
          name = "sub2api";
          env = [ "SUB2API_API_KEY" ];
          package = "@opencode/ai/providers/openai-compatible";
          # 中转站后面的模型以 DeepSeek/GLM 一类为主，统一按 max_tokens 发送。
          compatibility = {
            maxTokensField = "max_tokens";
          };
          settings = {
            baseURL = "https://sub2api.tail09f287.ts.net/v1";
            apiKey = "{env:SUB2API_API_KEY}";
          };
          models = {
            "deepseek-v4.1-flash" = mkSub2apiModel {
              name = "DeepSeek V4.1 Flash";
              context = 1000000;
              output = 384000;
              input = [ "text" "image" ];
              effort = [ "low" "high" "max" ];
            };
            "glm-5.3-flash" = mkSub2apiModel {
              name = "GLM-5.3-Flash";
              context = 1000000;
              output = 131072;
              input = [ "text" "image" "video" "pdf" ];
              effort = [ "low" "high" "max" ];
            };
            "glm-5.3" = mkSub2apiModel {
              name = "GLM-5.3";
              context = 1000000;
              output = 131072;
              effort = [ "low" "high" "max" ];
            };
            "kimi-k3" = mkSub2apiModel {
              name = "Kimi K3";
              context = 1048576;
              output = 131072;
              input = [ "text" "image" "video" ];
              effort = [ "max" ];
            };
            "kimi-k2.7-code" = mkSub2apiModel {
              name = "Kimi K2.7 Code";
              context = 262144;
              output = 262144;
              input = [ "text" "image" "video" ];
            };
            "minimax-m3" = mkSub2apiModel {
              name = "MiniMax-M3";
              context = 1000000;
              output = 131072;
              input = [ "text" "image" "video" ];
            };
            "qwen3.8-max" = mkSub2apiModel {
              name = "Qwen3.8 Max";
              context = 1000000;
              output = 131072;
              input = [ "text" "image" "video" ];
              effort = [ "low" "medium" "xhigh" ];
            };
            "qwen3.8-flash" = mkSub2apiModel {
              name = "Qwen3.8 Flash";
              context = 1000000;
              output = 131072;
              input = [ "text" "image" "video" ];
              effort = [ "low" "medium" "xhigh" ];
            };
            "mimo-v2.6-pro" = mkSub2apiModel {
              name = "MiMo-V2.6-Pro";
              context = 1048576;
              output = 131072;
              input = [ "text" "image" "audio" "video" ];
            };
            "mimo-v2.6-flash" = mkSub2apiModel {
              name = "MiMo-V2.6-Flash";
              context = 1048576;
              output = 131072;
              input = [ "text" "image" "audio" "video" ];
            };
          };
        };
      };
    };
  };
}
