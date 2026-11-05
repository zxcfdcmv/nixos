# DeepSeek Harness (dsh) —— 只装 CLI + Web UI，不装 desktop
#
# 依赖 flake.nix 里的 input 和 NixOS 级 overlay：
#   inputs.deepseek-harness.url = "git+https://gh.wha1e.dpdns.org/github.com/Moraxyc/deepseek-harness.nix?shallow=1";
#   nixpkgs.overlays = [ inputs.deepseek-harness.overlays.default ];
#
# 数据目录从默认的 ~/.dsh 改到 ~/.local/share/dsh（DSH_HOME）。
# skills 仍然由 agent-skills 写到 ~/.agents/skills，dsh 通过 DSH_AGENTS_HOME
# 读取，和 DSH_HOME 无关，所以改目录不影响 skills。
{ config, pkgs, lib, inputs, userSettings, ... }:

let
  # zed 里的 max_tokens 是上下文窗口，这里对应 dsh 的 contextWindow。
  # 需要视觉的模型显式声明 input；不写则按文本模型处理。
  cfModels = [
    { id = "google-ai-studio/gemini-3.8-flash"; name = "Gemini 3.8 Flash"; contextWindow = 1048576; input = [ "text" "image" ]; }
    { id = "google-ai-studio/gemini-3.5-flash"; name = "Gemini 3.5 Flash"; contextWindow = 1048576; input = [ "text" "image" ]; }
    { id = "google-ai-studio/gemini-3.5-flash-lite"; name = "Gemini 3.5 Flash-Lite"; contextWindow = 1048576; input = [ "text" "image" ]; }
    { id = "google-ai-studio/gemini-3.6-flash"; name = "Gemini 3.6 Flash"; contextWindow = 1048576; input = [ "text" "image" ]; }
    { id = "google-ai-studio/gemini-3.1-flash-lite"; name = "Gemini 3.1 Flash-Lite"; contextWindow = 1048576; input = [ "text" "image" ]; }

    { id = "custom-glm/glm-4-flash-250414"; name = "GLM 4 Flash(glm)"; contextWindow = 131072; }
    { id = "custom-glm/glm-4.5-flash"; name = "GLM 4.5 Flash(glm)"; contextWindow = 131072; }
    { id = "custom-glm/glm-4.7-flash"; name = "GLM 4.7 Flash(glm)"; contextWindow = 200000; }
    { id = "custom-glm/glm-5.3"; name = "GLM-5.3 pro(glm)"; contextWindow = 131072; }

    { id = "custom-nov/glm-4.7-flash"; name = "GLM 4.7 Flash(nov)"; contextWindow = 200000; }
    { id = "custom-nov/glm-4.6v-flash"; name = "GLM 4.6v Flash(nov)"; contextWindow = 128000; input = [ "text" "image" ]; }
    { id = "custom-nov/glm-4.1v-thinking-flash"; name = "GLM 4.1v thinking Flash(nov)"; contextWindow = 128000; input = [ "text" "image" ]; }

    { id = "custom-nv/z-ai/glm-5.3-flash"; name = "GLM 5.3 Flash(Nvidia)"; contextWindow = 1048576; }
    { id = "custom-nv/deepseek-ai/deepseek-v4.1-flash"; name = "DeepSeek 4.1 Flash(Nvidia)"; contextWindow = 1048576; }
    { id = "custom-nv/minimaxai/minimax-m3.1-flash"; name = "MiniMax m3.1 Flash(Nvidia)"; contextWindow = 1048576; }
    { id = "custom-nv/openai/gpt-oss-20b"; name = "GPT OSS 20b(Nvidia)"; contextWindow = 1048576; }
    { id = "custom-nv/nvidia/nemotron-3-ultra-550b-a55b"; name = "Nemotron 3 Ultra 550b a55b(Nvidia)"; contextWindow = 1048576; }
    { id = "custom-nv/nvidia/nemotron-3-super-120b-a12b"; name = "Nemotron 3 Super 120b a12b(Nvidia)"; contextWindow = 1048576; }
    { id = "custom-nv/google/gemma-4-31b-it"; name = "Google Gemma 4 31b it(Nvidia)"; contextWindow = 1048576; }
    { id = "custom-nv/meta/llama-3.2-90b-vision-instruct"; name = "llama 3.2 90b(Nvidia)"; contextWindow = 1048576; input = [ "text" "image" ]; }
    { id = "custom-nv/google/diffusiongemma-26b-a4b-it"; name = "Google Diffusiongemma 26b a4b(Nvidia)"; contextWindow = 1048576; }

    { id = "custom-sen/sensenova-6.8-flash"; name = "Sensenova 6.8 flash"; contextWindow = 1048576; }
    { id = "custom-sen/sensenova-6.8-flash-lite"; name = "Sensenova 6.8 flash lite"; contextWindow = 1048576; }
    { id = "custom-sen/deepseek-v4-flash"; name = "deepseek v4 flash(sensenova)"; contextWindow = 1048576; }
    { id = "custom-sen/deepseek-flash"; name = "deepseek v4.1 flash(sensenova)"; contextWindow = 1048576; }
    { id = "custom-sen/glm-5.2"; name = "GLM 5.2(sensenova)"; contextWindow = 1048576; }
    { id = "custom-sen/kimi-k3"; name = "Kimi k3(sensenova)"; contextWindow = 1048576; }
  ];

  cfGatewayBase = "https://gateway.ai.cloudflare.com/v1/${userSettings.account_id}/${userSettings.gateway}";

  # OpenCode Go 订阅里额度给得多的 flash / free 模型。
  # 不写 maxTokens：那会变成每个请求的默认输出上限，交给
  # defaultMaxTokens 统一兜底，模型自身能力仍按真实 contextWindow 声明。
  goModels = [
    { id = "deepseek-v4.1-flash"; name = "DeepSeek V4.1 Flash"; contextWindow = 1000000; input = [ "text" "image" ]; }
    { id = "glm-5.3-flash"; name = "GLM-5.3-Flash"; contextWindow = 1000000; input = [ "text" "image" ]; }
    { id = "longcat-2.0"; name = "LongCat-2.0"; contextWindow = 1000000; }
    { id = "minimax-m3"; name = "MiniMax-M3"; contextWindow = 1000000; input = [ "text" "image" ]; }
    { id = "qwen3.7-plus"; name = "Qwen3.7 Plus"; contextWindow = 1000000; input = [ "text" "image" ]; }
    { id = "hy3"; name = "Hy3"; contextWindow = 256000; }
    { id = "mimo-v2.6-flash"; name = "MiMo-V2.6-Flash"; contextWindow = 1048576; input = [ "text" "image" ]; }
    { id = "qwen3.8-flash"; name = "Qwen3.8 Flash"; contextWindow = 1000000; input = [ "text" "image" ]; }
    { id = "minimax-m3.1-flash"; name = "MiniMax M3.1 Flash"; contextWindow = 1000000; input = [ "text" "image" ]; }
    { id = "muse-spark-1.3-contributor"; name = "Muse Spark 1.3 Contributor"; contextWindow = 1048576; input = [ "text" "image" ]; }
    { id = "beam-free"; name = "Beam Free"; contextWindow = 1048576; }
    { id = "iceman-contributor-free"; name = "Iceman Contributor Free"; contextWindow = 262144; }
  ];

  # Obscura 不支持 proxy bypass：只要 NO_PROXY / no_proxy /
  # AGENT_BROWSER_PROXY_BYPASS 存在（哪怕是空值）就会拒绝启动。
  agentBrowserObscura = pkgs.writeShellScript "agent-browser-obscura" ''
    unset NO_PROXY no_proxy AGENT_BROWSER_PROXY_BYPASS
    exec ${lib.getExe pkgs.agent-browser} "$@"
  '';

  # dsh 的 profile patch 是 YAML。用原始 YAML 是为了保留注释和
  # 方便以后再加 !!js 表达式（密钥不要写进 Nix store）。
  mcpPatch = ''
    # zed 的 mcp.servers 不会被 dsh 读取；dsh 每台服务器需要一个
    # @deepseek-ai/dsh-mcp-client 条目。
    - insert:
        - id: mcp-docforge
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: docforge
            transport: stdio
            command: ${lib.getExe' pkgs.uv "uvx"}
            args: ['docforge-mcp']

        # 文件搜索用 dsh 内置的 glob/grep（dsh-tool-fs-search），
        # 不再需要 mcp-ripgrep。

        # agent-browser 的 mcp 子命令只接受 --tools；引擎/可执行文件/无头
        # 模式要通过 AGENT_BROWSER_* 环境变量给。
        # 每个 MCP server 用独立 session，避免 dsh 和 Zed/OpenCode 共用
        # 同一个 agent-browser daemon；共用时一个客户端会把 daemon 占住，
        # 另一个就报 "Resource temporarily unavailable"。
        - id: mcp-agent-browser-fast
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: agent-browser-fast
            transport: stdio
            command: ${agentBrowserObscura}
            args: ['mcp']
            # 浏览器冷启动/首次启动可能超过默认 60s
            toolCallTimeoutMs: 180000
            env:
              AGENT_BROWSER_ENGINE: obscura
              AGENT_BROWSER_EXECUTABLE_PATH: ${lib.getExe pkgs.obscura}
              AGENT_BROWSER_SESSION: dsh-fast

        - id: mcp-agent-browser-vision
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: agent-browser-vision
            transport: stdio
            command: ${lib.getExe pkgs.agent-browser}
            args: ['mcp']
            toolCallTimeoutMs: 180000
            env:
              AGENT_BROWSER_ENGINE: chrome
              AGENT_BROWSER_EXECUTABLE_PATH: ${lib.getExe pkgs.microsoft-edge}
              AGENT_BROWSER_SESSION: dsh-vision

        - id: mcp-git
          name: '@deepseek-ai/dsh-mcp-client'
          config:
            serverName: git
            transport: stdio
            command: ${lib.getExe' pkgs.uv "uvx"}
            args: ['mcp-server-git']

        # 记忆和视觉改用原生插件（graph-memory / modlens），
        # 不再需要 mcp-memory 和 mcp-deepseek-visionary。
  '';
in
{
  imports = [ inputs.deepseek-harness.homeModules.default ];

  programs.dsh = {
    enable = true;

    # 上游的 dshBundleCheckHook 会在 sandbox 里（无网络、无 /bin/sh）
    # 启动 nix-web profile 并等 60s 的 web endpoint。我们配的 MCP 服务器
    # 用的是 uvx/npx，在 sandbox 里必然起不来，所以这个检查过不了。
    # 上游给的逃生口就是 dontDshBundleCheck。
    package = pkgs.dsh.dsh.overrideAttrs (_: { dontDshBundleCheck = "1"; });

    # 标准 XDG 数据目录；dsh 自己默认是 ~/.dsh
    home = "${config.xdg.dataHome}/dsh";

    # Web 是 dsh 的官方主界面；TUI 是第三方 bundle（dsh-TUI），
    # 终端里直接跑 headless CLI 也行，但功能不如 Web 完整。
    profiles.web = {
      bundles = [
        pkgs.dsh.bundles.web-app
        pkgs.dsh.bundles.modsearch
        pkgs.dsh.bundles.better-sidebar
        pkgs.dsh.bundles.experimental-terminal-bundle
        pkgs.dsh.bundles.usage-stats
        pkgs.dsh.bundles.experimental-session-search
        pkgs.dsh.bundles.modlens
        pkgs.dsh.bundles.graph-memory
      ];
      mode = "managed";
      patch = mcpPatch;
    };
    defaultProfile = config.programs.dsh.profiles.web.materializedName;

    # home 级 patch 对所有 profile 生效，写在 $DSH_HOME/cordis.patch.yml。
    # 这里放模型/提供商；MCP 放在 profile patch 里是因为需要 !!js。
    patch = [
      {
        id = "llm-pi-ai";
        config.providers = {
          cf_gateway = {
            displayName = "Cloudflare AI Gateway";
            apiKeyEnv = "CF_GATEWAY_API_KEY";
            api = "openai-completions";
            baseURL = "${cfGatewayBase}/compat";
            # 大多数 OpenAI 兼容网关需要这两个兼容开关
            compat = {
              supportsDeveloperRole = false;
              maxTokensField = "max_tokens";
            };
            defaultContextWindow = 262144;
            defaultMaxTokens = 32768;
            models = cfModels;
          };

          openrouter = {
            displayName = "OpenRouter (Cloudflare AI Gateway)";
            apiKeyEnv = "OPENROUTER_API_KEY";
            api = "openai-completions";
            baseURL = "${cfGatewayBase}/openrouter";
            compat = {
              supportsDeveloperRole = false;
              maxTokensField = "max_tokens";
            };
            defaultContextWindow = 262144;
            defaultMaxTokens = 32768;
            models = [
              { id = "openrouter/free"; name = "OpenRouter Free Router"; contextWindow = 1048576; }
            ];
          };

          opencode_go = {
            displayName = "OpenCode Go";
            apiKeyEnv = "OPENCODE_API_KEY";
            api = "openai-completions";
            # Go 订阅的 OpenAI 兼容入口；PAYG 是 /inference 下的另一条路由。
            baseURL = "https://opencode.ai/inference/go/openai/v1";
            # OpenCode Go 要求请求带 x-opencode-session，否则返回
            # 400 MissingSessionID。dsh 的 OpenAI 兼容适配器不会自动加，
            # 这里先给一个稳定的进程级 ID（满足路由/缓存的最小要求）。
            headers = {
              "x-opencode-session" = "dsh";
            };
            compat = {
              supportsDeveloperRole = false;
              maxTokensField = "max_tokens";
            };
            defaultContextWindow = 262144;
            defaultMaxTokens = 32768;
            models = goModels;
          };
        };
      }
    ];
  };

  # 普通 dsh 不会自动带上网关密钥；用 rbw 在启动时注入，
  # 和你的 zed-ai 包装脚本一致。想直接跑普通 dsh 的话，
  # 用 dsh-ai 代替 dsh 即可。
  #
  # 视觉已改用原生 modlens 插件，不再需要 deepseek-visionary 的
  # DEEPSEEK_USER_TOKEN。modlens 的引擎在 ~/.modlens/config.json 里配，
  # 也可以复用本机 opencode 的视觉模型。
  home.packages = [
    # modlens 的 CLI 平时只能从 dsh bundle 的 store 路径里跑；
    # 这里给它一个稳定的命令名，方便手动 doctor / analyze / 改配置。
    (pkgs.writeShellScriptBin "modlens" ''
      exec ${pkgs.nodejs}/bin/node ${pkgs.dsh.bundles.modlens}/lib/node_modules/@liustack/modlens/dist/main.js "$@"
    '')

    (pkgs.writeShellScriptBin "dsh-ai" ''
      export DSH_HOME="${config.xdg.dataHome}/dsh"
      export CF_GATEWAY_API_KEY="$(${lib.getExe pkgs.rbw} get cloudflare-aig)"
      export OPENROUTER_API_KEY="$CF_GATEWAY_API_KEY"
      export OPENCODE_API_KEY="$(${lib.getExe pkgs.rbw} get ai-opencode)"
      exec dsh "$@"
    '')
  ];
}
