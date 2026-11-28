# oh-my-pi 配置。
#
# 模型和 MCP 不在这里另抄一份：CF 模型来自 cf-models.nix，MCP 直接读
# ai.nix 声明的 programs.mcp.servers，AGENTS.md 复用 opencode 生成的那份，
# 避免 opencode / omp 两边列表和规则漂移。
{ config, pkgs, lib, inputs, userSettings, ... }:

let
  cf = import ./cf-models.nix { inherit lib; };

  gatewayBase = "https://gateway.ai.cloudflare.com/v1/${userSettings.account_id}/${userSettings.gateway}";

  # omp 的 input 只接受 text/image；video/pdf/audio 在 opencode 里有声明，
  # omp 没有对应字段，过滤掉，不影响实际请求。
  ompInput = input: builtins.filter (x: x == "text" || x == "image") input;

  mkCfModel = model: {
    inherit (model) id name;
    contextWindow = model.context;
    maxTokens = 32768;
    input = ompInput (if model.vision then [ "text" "image" ] else [ "text" ]);
  };

  # 名称 / 上下文 / 输出与 opencode.nix 的 sub2api 列表保持一致。
  sub2apiModels = [
    {
      id = "deepseek-v4.1-flash";
      name = "DeepSeek V4.1 Flash";
      context = 1000000;
      output = 384000;
      input = [ "text" "image" ];
      effort = [ "low" "high" "max" ];
    }
    {
      id = "glm-5.3-flash";
      name = "GLM-5.3-Flash";
      context = 1000000;
      output = 131072;
      input = [ "text" "image" "video" "pdf" ];
      effort = [ "low" "high" "max" ];
    }
    {
      id = "glm-5.3";
      name = "GLM-5.3";
      context = 1000000;
      output = 131072;
      input = [ "text" ];
      effort = [ "low" "high" "max" ];
    }
    {
      id = "kimi-k3.1-pro";
      name = "Kimi K3.1 Pro";
      context = 1048576;
      output = 131072;
      input = [ "text" "image" "video" ];
      effort = [ "max" ];
    }
    {
      id = "kimi-k2.7-code";
      name = "Kimi K2.7 Code";
      context = 262144;
      output = 262144;
      input = [ "text" "image" "video" ];
    }
    {
      id = "minimax-m3.1-flash";
      name = "MiniMax-M3.1 Flash";
      context = 1000000;
      output = 131072;
      input = [ "text" "image" "video" ];
    }
    {
      id = "qwen4-max";
      name = "Qwen4 Max";
      context = 1000000;
      output = 131072;
      input = [ "text" "image" "video" ];
      effort = [ "low" "medium" "xhigh" ];
    }
    {
      id = "qwen3.8-flash";
      name = "Qwen3.8 Flash";
      context = 1000000;
      output = 131072;
      input = [ "text" "image" "video" ];
      effort = [ "low" "medium" "xhigh" ];
    }
    {
      id = "mimo-v2.6-pro";
      name = "MiMo-V2.6-Pro";
      context = 1048576;
      output = 131072;
      input = [ "text" "image" "audio" "video" ];
    }
    {
      id = "mimo-v2.6-flash";
      name = "MiMo-V2.6-Flash";
      context = 1048576;
      output = 131072;
      input = [ "text" "image" "audio" "video" ];
    }
  ];

  mkSub2apiModel = model: {
    inherit (model) id name;
    contextWindow = model.context;
    maxTokens = model.output;
    input = ompInput model.input;
  } // lib.optionalAttrs ((model.effort or null) != null) {
    reasoning = true;
    thinking = {
      mode = "effort";
      efforts = model.effort;
    };
  };

  models = {
    providers = {
      sub2api = {
        baseUrl = "https://sub2api.tail09f287.ts.net/v1";
        api = "openai-completions";
        apiKey = "!rbw get sub2api";
        compat.maxTokensField = "max_tokens";
        models = map mkSub2apiModel sub2apiModels;
      };

      cf_gateway = {
        baseUrl = "${gatewayBase}/compat";
        api = "openai-completions";
        apiKey = "!rbw get cloudflare-aig";
        compat.maxTokensField = "max_tokens";
        models = map mkCfModel cf.models;
      };

      openrouter_gw = {
        baseUrl = "${gatewayBase}/openrouter";
        api = "openai-completions";
        apiKey = "!rbw get cloudflare-aig";
        compat.maxTokensField = "max_tokens";
        models = [
          {
            id = "openrouter/free";
            name = "OpenRouter Free Router";
            contextWindow = 131072;
            maxTokens = 32768;
            input = [ "text" ];
          }
        ];
      };
    };
  };

  mcpServers =
    lib.mapAttrs
      (
        _: server:
        if server.url != null then
          {
            type = "http";
            inherit (server) url;
          }
          // lib.optionalAttrs (server.headers != { }) { inherit (server) headers; }
        else
          {
            inherit (server) command args;
          }
          // lib.optionalAttrs (server.env != { }) {
            env = lib.mapAttrs (
              _: value: if builtins.isString value then value else "!cat ${value.file}"
            ) server.env;
          }
      )
      (lib.filterAttrs (_: server: server.enabled != false) config.programs.mcp.servers);
in
{
  imports = [ inputs.omp.homeManagerModules.default ];

  programs.omp = {
    enable = true;
    # nixpkgs 的 omp 已有二进制缓存；上游 flake 的默认包要从源码编 Bun/Rust。
    package = pkgs.omp;

    settings = {
      modelRoles = {
        default = "sub2api/deepseek-v4.1-flash:high";
        smol = "cf_gateway/dynamic/free";
        slow = "sub2api/glm-5.3:high";
        plan = "sub2api/kimi-k3.1-pro:max";
        task = "cf_gateway/dynamic/free";
        vision = "cf_gateway/dynamic/vision";
        # tiny/memory 默认用本地小模型，首次运行会下载上百 MB 权重；
        # 指到远端模型就不落盘。
        tiny = "cf_gateway/dynamic/free";
        memory = "cf_gateway/dynamic/free";
      };
      startup.quiet = true;
    };
  };

  # JSON 是合法 YAML，直接 toJSON 生成，不必再走一遍 YAML 转换。
  home.file.".omp/agent/models.yml".text = builtins.toJSON models;
  home.file.".omp/agent/mcp.json".text = builtins.toJSON { inherit mcpServers; };
  home.file.".omp/agent/AGENTS.md".text = config.xdg.configFile."opencode/AGENTS.md".text;
}
