# OpenCode 提供商配置。
#
# 模型列表与 modules/ai/ai.nix 里 Zed 的 language_models 保持一致：
# 都走 Cloudflare AI Gateway，分别是 OpenAI 兼容入口和 OpenRouter 入口。
# 密钥沿用 zed-ai / dsh-ai 的做法，从 rbw 读取后在启动时注入。
{ config, pkgs, lib, userSettings, ... }:

let
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

  # 需要视觉的模型显式声明；其余按纯文本模型处理。
  cfModels = [
    { id = "google-ai-studio/gemini-3.8-flash"; name = "Gemini 3.8 Flash"; context = 1048576; vision = true; }
    { id = "google-ai-studio/gemini-3.5-flash"; name = "Gemini 3.5 Flash"; context = 1048576; vision = true; }
    { id = "google-ai-studio/gemini-3.5-flash-lite"; name = "Gemini 3.5 Flash-Lite"; context = 1048576; vision = true; }
    { id = "google-ai-studio/gemini-3.6-flash"; name = "Gemini 3.6 Flash"; context = 1048576; vision = true; }
    { id = "google-ai-studio/gemini-3.1-flash-lite"; name = "Gemini 3.1 Flash-Lite"; context = 1048576; vision = true; }

    { id = "custom-glm/glm-4-flash-250414"; name = "GLM 4 Flash(glm)"; context = 131072; }
    { id = "custom-glm/glm-4.5-flash"; name = "GLM 4.5 Flash(glm)"; context = 131072; }
    { id = "custom-glm/glm-4.7-flash"; name = "GLM 4.7 Flash(glm)"; context = 200000; }
    { id = "custom-glm/glm-5.3"; name = "GLM-5.3 pro(glm)"; context = 131072; }

    { id = "custom-nov/glm-4.7-flash"; name = "GLM 4.7 Flash(nov)"; context = 200000; }
    { id = "custom-nov/glm-4.6v-flash"; name = "GLM 4.6v Flash(nov)"; context = 128000; vision = true; }
    { id = "custom-nov/glm-4.1v-thinking-flash"; name = "GLM 4.1v thinking Flash(nov)"; context = 128000; vision = true; }

    { id = "custom-nv/z-ai/glm-5.3-flash"; name = "GLM 5.3 Flash(Nvidia)"; context = 1048576; }
    { id = "custom-nv/deepseek-ai/deepseek-v4.1-flash"; name = "DeepSeek 4.1 Flash(Nvidia)"; context = 1048576; }
    { id = "custom-nv/minimaxai/minimax-m3.1-flash"; name = "MiniMax m3.1 Flash(Nvidia)"; context = 1048576; }
    { id = "custom-nv/openai/gpt-oss-20b"; name = "GPT OSS 20b(Nvidia)"; context = 1048576; }
    { id = "custom-nv/nvidia/nemotron-3-ultra-550b-a55b"; name = "Nemotron 3 Ultra 550b a55b(Nvidia)"; context = 1048576; }
    { id = "custom-nv/nvidia/nemotron-3-super-120b-a12b"; name = "Nemotron 3 Super 120b a12b(Nvidia)"; context = 1048576; }
    { id = "custom-nv/google/gemma-4-31b-it"; name = "Google Gemma 4 31b it(Nvidia)"; context = 1048576; }
    { id = "custom-nv/meta/llama-3.2-90b-vision-instruct"; name = "llama 3.2 90b(Nvidia)"; context = 1048576; vision = true; }
    { id = "custom-nv/google/diffusiongemma-26b-a4b-it"; name = "Google Diffusiongemma 26b a4b(Nvidia)"; context = 1048576; }

    { id = "custom-sen/sensenova-6.8-flash"; name = "Sensenova 6.8 flash"; context = 1048576; }
    { id = "custom-sen/sensenova-6.8-flash-lite"; name = "Sensenova 6.8 flash lite"; context = 1048576; }
    { id = "custom-sen/deepseek-v4-flash"; name = "deepseek v4 flash(sensenova)"; context = 1048576; }
    { id = "custom-sen/deepseek-flash"; name = "deepseek v4.1 flash(sensenova)"; context = 1048576; }
    { id = "custom-sen/glm-5.2"; name = "GLM 5.2(sensenova)"; context = 1048576; }
    { id = "custom-sen/kimi-k3"; name = "Kimi k3(sensenova)"; context = 1048576; }
  ];

  cfModelSet = builtins.listToAttrs (map (model: {
    name = model.id;
    value = (mkModel model) // { modelID = model.id; };
  }) cfModels);

  openrouterModelSet = {
    # 选择器是 openrouter/free，发给网关的模型名仍是 openrouter/free。
    free = (mkModel { name = "OpenRouter Free Router"; context = 1048576; }) // {
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
      instructions = [
        "https://raw.githubusercontent.com/JRedeker/opencode-shell-strategy/trunk/shell_strategy.md"
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
