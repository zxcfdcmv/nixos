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

  # dsh-tool-search：把长尾工具 schema 折叠到 tool_search/describe/call 后面。
  # 包在 modules/ai/dsh-tool-search.nix，构建时共享 dsh-runtime 安装里的 peer 模块。
  dshToolSearch = pkgs.callPackage ./dsh-tool-search.nix {
    buildDshBundle = pkgs.dsh.buildDshBundle;
    dsh-runtime = pkgs.dsh.dsh-runtime;
  };

  # 第三方免费模型插件，只挂到独立的 free profile 里测试。
  dshOurFreeModel = pkgs.callPackage ./dsh-our-free-model.nix {
    buildDshBundle = pkgs.dsh.buildDshBundle;
    dsh-runtime = pkgs.dsh.dsh-runtime;
  };

  # ACP 上下文压缩后端。
  billionContext = pkgs.callPackage ./billion-context.nix {
    buildDshBundle = pkgs.dsh.buildDshBundle;
    dsh-runtime = pkgs.dsh.dsh-runtime;
  };

  # 上游 context bundle 的 src 直接 fetchFromGitHub 拉 github.com；
  # 本机直连 github 不稳定（甚至 DNS 失败），改走 flake.nix 里配置的
  # GitHub 代理。压缩包内容与上游一致，nar hash 不变。
  dshContext = pkgs.dsh.bundles.context.overrideAttrs (finalAttrs: {
    src = pkgs.fetchzip {
      url = "${userSettings.githubProxy}/https://github.com/bowenliang123/dsh-context/archive/refs/tags/v${finalAttrs.version}.tar.gz";
      hash = "sha256-AONdqsIMjgJ66pYTUmHUOfFDkTGaPbWmLQE76FcjU/U=";
    };
  });

  # Obscura 不支持 proxy bypass：只要 NO_PROXY / no_proxy /
  # AGENT_BROWSER_PROXY_BYPASS 存在（哪怕是空值）就会拒绝启动。
  # agentBrowserObscura = pkgs.writeShellScript "agent-browser-obscura" ''
  #   unset NO_PROXY no_proxy AGENT_BROWSER_PROXY_BYPASS
  #   exec ${lib.getExe pkgs.agent-browser} "$@"
  # '';

  # dsh 的 profile patch 是 YAML。
  #
  # 工具 schema 会进入每次请求的 system prompt，MCP 越多 prefill 越大，
  # 而且原生 MCP client 会常驻子进程。因此 MCP 不放在全局，而是放进
  # 自定义的 full preset；standard preset 保持精简（内置工具 + 全局
  # modlens/graph-memory + skills），新会话默认用它。
  # 浏览器/Office 日常用 agent-browser、docx 等 skill 走 CLI；
  # 需要 typed MCP 工具时，在新建会话时选 Full。
  profilePatch = ''
    - id: tool-search
      config:
        enabled: auto
        core:
          - read
          - write
          - edit
          - bash
          - grep
          - glob
          - todo_write
          - skill
          - ask_user_question
          - read_image
          - modlens_read_image
          - present
          - compress
          - decompress
          - search_context
          - acp_status

    - insert:
        - id: preset-docs
          name: '@deepseek-ai/dsh-agent-preset'
          inject: [biliBasicCompactionPolicy]
          config:
            id: docs
            name: Docs
            description: 编码工具 + docforge 文档转换（Word/PDF/Excel/PPT）。
            order: 10
            plugins:
              - id: persona
                name: '@deepseek-ai/dsh-persona'
                config:
                  prefix: You are a coding agent powered by the {{model}} model.
              - id: agent-instructions
                name: '@deepseek-ai/dsh-agent-instructions'
                config:
                  maxBytes: 65536
              - id: time-context
                name: '@deepseek-ai/dsh-time-context'
              - id: tool-bash
                name: '@deepseek-ai/dsh-tool-bash'
                disabled: !!js process.platform === 'win32'
              - id: tool-pwsh
                name: '@deepseek-ai/dsh-tool-pwsh'
                disabled: !!js process.platform !== 'win32'
              - id: tool-fs
                name: '@deepseek-ai/dsh-tool-fs'
                config:
                  # Set false to drop the apply_patch tool beside edit.
                  applyPatch: false
              - id: tool-fs-search
                name: '@deepseek-ai/dsh-tool-fs-search'
                config:
                  sampleOverCapGlobResults: false
              - id: tool-jobs
                name: '@deepseek-ai/dsh-tool-jobs'
              - id: tool-schedule
                name: '@deepseek-ai/dsh-tool-schedule'
              - id: skill-filesystem
                name: '@deepseek-ai/dsh-skill-filesystem'
              - id: tool-skill
                name: '@deepseek-ai/dsh-tool-skill'
              - id: command-goal
                name: '@deepseek-ai/dsh-command-goal'
              - id: tool-goal
                name: '@deepseek-ai/dsh-tool-goal'
              - id: planning
                name: cordis:group
                group: true
                isolate:
                  planMode: true
                config:
                  - id: plan-mode
                    name: '@deepseek-ai/dsh-plan-mode'
                    config:
                      section: |
                        You are in plan mode. Stay in plan mode until the user approves your plan through exit_plan_mode or switches the session mode. Imperative language to implement changes means plan the implementation, not execute it. A user's conversational agreement — including an answer confirming something you asked — approves nothing and does not end plan mode; fold the confirmed decision into the plan and submit it through exit_plan_mode.
                        Explore first. Use non-mutating reads, searches, static analysis, and checks to ground the plan in the actual repository. Do not edit or write files, change configuration, run formatters or code generation that rewrites tracked files, commit, or otherwise carry out the plan. Prefer existing functions and patterns over new machinery.
                        The tool catalog stays the same across modes for request-cache stability. These plan-mode rules override any later tool description or guidance that suggests using mutation tools; those tools remain listed to keep the tool catalog unchanged. Do not use todo_write to track this planning phase: it tracks implementation after an approved plan, while the plan itself belongs in exit_plan_mode.
                        Resolve discoverable facts by inspection. Use ask_user_question only for user-owned choices or material ambiguity that inspection cannot answer. Do not ask the user where code lives or how current behavior works when you can find out.
                        Make the plan decision-complete: state the goal and success criteria; group implementation changes by subsystem; identify public API, schema, and data-flow changes; cover edge cases, failure modes, tests, acceptance criteria, and explicit assumptions. Keep it concise enough to review but detailed enough that another engineer can implement it without making design decisions.
                        When ready, call exit_plan_mode with the complete plan markdown, starting with a # title. Make exit_plan_mode the only and final tool call in that assistant response: it presents the plan for approval, and implementation begins only in a later step after approval. Do not paste the final plan as a plain reply or ask "should I proceed?" through prose or ask_user_question. If review rejects it, incorporate the feedback and present again. If the review channel is unavailable or aborted, stay in plan mode and ask the user to switch modes manually; do not proceed with implementation.
              - id: compaction
                name: cordis:group
                group: true
                isolate:
                  compaction: true
                  toolResultPruner: true
                config:
                  - id: compaction-basic
                    name: '@deepseek-ai/dsh-compaction-basic'
                  - id: command-compact
                    name: '@deepseek-ai/dsh-command-compact'
                  - id: tool-result-pruner
                    name: '@deepseek-ai/dsh-compaction-tool-result-pruner'
                    config:
                      thresholdChars: 8192
                      headChars: 4096
                      tailChars: 1024
              - id: delegation
                name: cordis:group
                group: true
                isolate:
                  workflowEngine: true
                config:
                  - id: tool-subagent-control
                    name: '@deepseek-ai/dsh-tool-subagent-control'
                  - id: tool-subagent
                    name: '@deepseek-ai/dsh-tool-subagent'
                    config:
                      provider: spawn
                      toolName: subagent
                      modelSelection: true
                      modelDiscovery: true
                  - id: tool-subagent-fork
                    name: '@deepseek-ai/dsh-tool-subagent'
                    config:
                      provider: fork
                      toolName: subagent_fork
                  - id: workflow-ptc
                    name: '@deepseek-ai/dsh-workflow-ptc'
                    config:
                      provider: spawn
                  - id: tool-workflow
                    name: '@deepseek-ai/dsh-tool-workflow'
              - id: tool-ask-user
                name: '@deepseek-ai/dsh-tool-ask-user'
              - id: tool-todo
                name: '@deepseek-ai/dsh-tool-todo'
                config:
                  allowParallelInProgress: true
              - id: tool-web
                name: '@deepseek-ai/dsh-tool-web'
                config:
                  fetch: true
                  searchTimeoutMs: 60000
              - id: present
                name: '@deepseek-ai/dsh-tool-present'
              - id: tool-plugin-manager
                name: '@deepseek-ai/dsh-plugin-manager/tools'
                disabled: !!js "!ctx.get('profileContext')"
              - id: tool-plugin-market
                name: '@deepseek-ai/dsh-plugin-market/tools'
                disabled: true
              - id: mcp-docforge
                name: '@deepseek-ai/dsh-mcp-client'
                config:
                  serverName: docforge
                  transport: stdio
                  command: ${lib.getExe' pkgs.uv "uvx"}
                  args: ['docforge-mcp']
        - id: preset-browser
          name: '@deepseek-ai/dsh-agent-preset'
          inject: [biliBasicCompactionPolicy]
          config:
            id: browser
            name: Browser
            description: 编码工具 + agent-browser 自动化与截图。
            order: 11
            plugins:
              - id: persona
                name: '@deepseek-ai/dsh-persona'
                config:
                  prefix: You are a coding agent powered by the {{model}} model.
              - id: agent-instructions
                name: '@deepseek-ai/dsh-agent-instructions'
                config:
                  maxBytes: 65536
              - id: time-context
                name: '@deepseek-ai/dsh-time-context'
              - id: tool-bash
                name: '@deepseek-ai/dsh-tool-bash'
                disabled: !!js process.platform === 'win32'
              - id: tool-pwsh
                name: '@deepseek-ai/dsh-tool-pwsh'
                disabled: !!js process.platform !== 'win32'
              - id: tool-fs
                name: '@deepseek-ai/dsh-tool-fs'
                config:
                  # Set false to drop the apply_patch tool beside edit.
                  applyPatch: false
              - id: tool-fs-search
                name: '@deepseek-ai/dsh-tool-fs-search'
                config:
                  sampleOverCapGlobResults: false
              - id: tool-jobs
                name: '@deepseek-ai/dsh-tool-jobs'
              - id: tool-schedule
                name: '@deepseek-ai/dsh-tool-schedule'
              - id: skill-filesystem
                name: '@deepseek-ai/dsh-skill-filesystem'
              - id: tool-skill
                name: '@deepseek-ai/dsh-tool-skill'
              - id: command-goal
                name: '@deepseek-ai/dsh-command-goal'
              - id: tool-goal
                name: '@deepseek-ai/dsh-tool-goal'
              - id: planning
                name: cordis:group
                group: true
                isolate:
                  planMode: true
                config:
                  - id: plan-mode
                    name: '@deepseek-ai/dsh-plan-mode'
                    config:
                      section: |
                        You are in plan mode. Stay in plan mode until the user approves your plan through exit_plan_mode or switches the session mode. Imperative language to implement changes means plan the implementation, not execute it. A user's conversational agreement — including an answer confirming something you asked — approves nothing and does not end plan mode; fold the confirmed decision into the plan and submit it through exit_plan_mode.
                        Explore first. Use non-mutating reads, searches, static analysis, and checks to ground the plan in the actual repository. Do not edit or write files, change configuration, run formatters or code generation that rewrites tracked files, commit, or otherwise carry out the plan. Prefer existing functions and patterns over new machinery.
                        The tool catalog stays the same across modes for request-cache stability. These plan-mode rules override any later tool description or guidance that suggests using mutation tools; those tools remain listed to keep the tool catalog unchanged. Do not use todo_write to track this planning phase: it tracks implementation after an approved plan, while the plan itself belongs in exit_plan_mode.
                        Resolve discoverable facts by inspection. Use ask_user_question only for user-owned choices or material ambiguity that inspection cannot answer. Do not ask the user where code lives or how current behavior works when you can find out.
                        Make the plan decision-complete: state the goal and success criteria; group implementation changes by subsystem; identify public API, schema, and data-flow changes; cover edge cases, failure modes, tests, acceptance criteria, and explicit assumptions. Keep it concise enough to review but detailed enough that another engineer can implement it without making design decisions.
                        When ready, call exit_plan_mode with the complete plan markdown, starting with a # title. Make exit_plan_mode the only and final tool call in that assistant response: it presents the plan for approval, and implementation begins only in a later step after approval. Do not paste the final plan as a plain reply or ask "should I proceed?" through prose or ask_user_question. If review rejects it, incorporate the feedback and present again. If the review channel is unavailable or aborted, stay in plan mode and ask the user to switch modes manually; do not proceed with implementation.
              - id: compaction
                name: cordis:group
                group: true
                isolate:
                  compaction: true
                  toolResultPruner: true
                config:
                  - id: compaction-basic
                    name: '@deepseek-ai/dsh-compaction-basic'
                  - id: command-compact
                    name: '@deepseek-ai/dsh-command-compact'
                  - id: tool-result-pruner
                    name: '@deepseek-ai/dsh-compaction-tool-result-pruner'
                    config:
                      thresholdChars: 8192
                      headChars: 4096
                      tailChars: 1024
              - id: delegation
                name: cordis:group
                group: true
                isolate:
                  workflowEngine: true
                config:
                  - id: tool-subagent-control
                    name: '@deepseek-ai/dsh-tool-subagent-control'
                  - id: tool-subagent
                    name: '@deepseek-ai/dsh-tool-subagent'
                    config:
                      provider: spawn
                      toolName: subagent
                      modelSelection: true
                      modelDiscovery: true
                  - id: tool-subagent-fork
                    name: '@deepseek-ai/dsh-tool-subagent'
                    config:
                      provider: fork
                      toolName: subagent_fork
                  - id: workflow-ptc
                    name: '@deepseek-ai/dsh-workflow-ptc'
                    config:
                      provider: spawn
                  - id: tool-workflow
                    name: '@deepseek-ai/dsh-tool-workflow'
              - id: tool-ask-user
                name: '@deepseek-ai/dsh-tool-ask-user'
              - id: tool-todo
                name: '@deepseek-ai/dsh-tool-todo'
                config:
                  allowParallelInProgress: true
              - id: tool-web
                name: '@deepseek-ai/dsh-tool-web'
                config:
                  fetch: true
                  searchTimeoutMs: 60000
              - id: present
                name: '@deepseek-ai/dsh-tool-present'
              - id: tool-plugin-manager
                name: '@deepseek-ai/dsh-plugin-manager/tools'
                disabled: !!js "!ctx.get('profileContext')"
              - id: tool-plugin-market
                name: '@deepseek-ai/dsh-plugin-market/tools'
                disabled: true
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
              # - id: mcp-agent-browser-fast
              #   name: '@deepseek-ai/dsh-mcp-client'
              #   config:
              #     serverName: agent-browser-fast
              #     transport: stdio
              #     command: ${agentBrowserObscura}
              #     args: ['mcp']
              #     toolCallTimeoutMs: 180000
              #     env:
              #       AGENT_BROWSER_ENGINE: obscura
              #       AGENT_BROWSER_EXECUTABLE_PATH: ${lib.getExe pkgs.obscura}
              #       AGENT_BROWSER_SESSION: dsh-fast
        - id: preset-full
          name: '@deepseek-ai/dsh-agent-preset'
          inject: [biliBasicCompactionPolicy]
          config:
            id: full
            name: Full
            description: 编码工具 + 文档与浏览器 MCP 全套。
            order: 12
            plugins:
              - id: persona
                name: '@deepseek-ai/dsh-persona'
                config:
                  prefix: You are a coding agent powered by the {{model}} model.
              - id: agent-instructions
                name: '@deepseek-ai/dsh-agent-instructions'
                config:
                  maxBytes: 65536
              - id: time-context
                name: '@deepseek-ai/dsh-time-context'
              - id: tool-bash
                name: '@deepseek-ai/dsh-tool-bash'
                disabled: !!js process.platform === 'win32'
              - id: tool-pwsh
                name: '@deepseek-ai/dsh-tool-pwsh'
                disabled: !!js process.platform !== 'win32'
              - id: tool-fs
                name: '@deepseek-ai/dsh-tool-fs'
                config:
                  # Set false to drop the apply_patch tool beside edit.
                  applyPatch: false
              - id: tool-fs-search
                name: '@deepseek-ai/dsh-tool-fs-search'
                config:
                  sampleOverCapGlobResults: false
              - id: tool-jobs
                name: '@deepseek-ai/dsh-tool-jobs'
              - id: tool-schedule
                name: '@deepseek-ai/dsh-tool-schedule'
              - id: skill-filesystem
                name: '@deepseek-ai/dsh-skill-filesystem'
              - id: tool-skill
                name: '@deepseek-ai/dsh-tool-skill'
              - id: command-goal
                name: '@deepseek-ai/dsh-command-goal'
              - id: tool-goal
                name: '@deepseek-ai/dsh-tool-goal'
              - id: planning
                name: cordis:group
                group: true
                isolate:
                  planMode: true
                config:
                  - id: plan-mode
                    name: '@deepseek-ai/dsh-plan-mode'
                    config:
                      section: |
                        You are in plan mode. Stay in plan mode until the user approves your plan through exit_plan_mode or switches the session mode. Imperative language to implement changes means plan the implementation, not execute it. A user's conversational agreement — including an answer confirming something you asked — approves nothing and does not end plan mode; fold the confirmed decision into the plan and submit it through exit_plan_mode.
                        Explore first. Use non-mutating reads, searches, static analysis, and checks to ground the plan in the actual repository. Do not edit or write files, change configuration, run formatters or code generation that rewrites tracked files, commit, or otherwise carry out the plan. Prefer existing functions and patterns over new machinery.
                        The tool catalog stays the same across modes for request-cache stability. These plan-mode rules override any later tool description or guidance that suggests using mutation tools; those tools remain listed to keep the tool catalog unchanged. Do not use todo_write to track this planning phase: it tracks implementation after an approved plan, while the plan itself belongs in exit_plan_mode.
                        Resolve discoverable facts by inspection. Use ask_user_question only for user-owned choices or material ambiguity that inspection cannot answer. Do not ask the user where code lives or how current behavior works when you can find out.
                        Make the plan decision-complete: state the goal and success criteria; group implementation changes by subsystem; identify public API, schema, and data-flow changes; cover edge cases, failure modes, tests, acceptance criteria, and explicit assumptions. Keep it concise enough to review but detailed enough that another engineer can implement it without making design decisions.
                        When ready, call exit_plan_mode with the complete plan markdown, starting with a # title. Make exit_plan_mode the only and final tool call in that assistant response: it presents the plan for approval, and implementation begins only in a later step after approval. Do not paste the final plan as a plain reply or ask "should I proceed?" through prose or ask_user_question. If review rejects it, incorporate the feedback and present again. If the review channel is unavailable or aborted, stay in plan mode and ask the user to switch modes manually; do not proceed with implementation.
              - id: compaction
                name: cordis:group
                group: true
                isolate:
                  compaction: true
                  toolResultPruner: true
                config:
                  - id: compaction-basic
                    name: '@deepseek-ai/dsh-compaction-basic'
                  - id: command-compact
                    name: '@deepseek-ai/dsh-command-compact'
                  - id: tool-result-pruner
                    name: '@deepseek-ai/dsh-compaction-tool-result-pruner'
                    config:
                      thresholdChars: 8192
                      headChars: 4096
                      tailChars: 1024
              - id: delegation
                name: cordis:group
                group: true
                isolate:
                  workflowEngine: true
                config:
                  - id: tool-subagent-control
                    name: '@deepseek-ai/dsh-tool-subagent-control'
                  - id: tool-subagent
                    name: '@deepseek-ai/dsh-tool-subagent'
                    config:
                      provider: spawn
                      toolName: subagent
                      modelSelection: true
                      modelDiscovery: true
                  - id: tool-subagent-fork
                    name: '@deepseek-ai/dsh-tool-subagent'
                    config:
                      provider: fork
                      toolName: subagent_fork
                  - id: workflow-ptc
                    name: '@deepseek-ai/dsh-workflow-ptc'
                    config:
                      provider: spawn
                  - id: tool-workflow
                    name: '@deepseek-ai/dsh-tool-workflow'
              - id: tool-ask-user
                name: '@deepseek-ai/dsh-tool-ask-user'
              - id: tool-todo
                name: '@deepseek-ai/dsh-tool-todo'
                config:
                  allowParallelInProgress: true
              - id: tool-web
                name: '@deepseek-ai/dsh-tool-web'
                config:
                  fetch: true
                  searchTimeoutMs: 60000
              - id: present
                name: '@deepseek-ai/dsh-tool-present'
              - id: tool-plugin-manager
                name: '@deepseek-ai/dsh-plugin-manager/tools'
                disabled: !!js "!ctx.get('profileContext')"
              - id: tool-plugin-market
                name: '@deepseek-ai/dsh-plugin-market/tools'
                disabled: true
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
              # - id: mcp-agent-browser-fast
              #   name: '@deepseek-ai/dsh-mcp-client'
              #   config:
              #     serverName: agent-browser-fast
              #     transport: stdio
              #     command: ${agentBrowserObscura}
              #     args: ['mcp']
              #     toolCallTimeoutMs: 180000
              #     env:
              #       AGENT_BROWSER_ENGINE: obscura
              #       AGENT_BROWSER_EXECUTABLE_PATH: ${lib.getExe pkgs.obscura}
              #       AGENT_BROWSER_SESSION: dsh-fast
              - id: mcp-docforge
                name: '@deepseek-ai/dsh-mcp-client'
                config:
                  serverName: docforge
                  transport: stdio
                  command: ${lib.getExe' pkgs.uv "uvx"}
                  args: ['docforge-mcp']

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
        dshContext
        pkgs.dsh.bundles.experimental-cot-translation-bundle
        dshToolSearch
        dshOurFreeModel
        billionContext
      ];
      mode = "managed";
      patch = profilePatch;
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
            # OpenCode Go 的 DeepSeek 预填充池经常短时间满载，默认 5 次
            # 重试（最长 10s）有时不够；放宽到 8 次、最长 30s。
            retryPolicy = {
              mode = "normal";
              maxRetries = 8;
              retryableCodes = [
                "EMPTY_RESPONSE"
                "RATE_LIMIT"
                "SERVER"
                "TIMEOUT"
                "TRANSPORT"
                "MALFORMED_RESPONSE"
              ];
              backoff = {
                initialDelayMs = 1000;
                maxDelayMs = 30000;
                jitterRatio = 0.2;
              };
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
  # 给 dsh-tool-search 一个初始分组；只在该文件不存在时写入，
  # 之后 Web 里的 tool-slimmer-setup skill 可以继续修改它。
  home.activation.dshToolSearchSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="${config.xdg.dataHome}/dsh/dsh-tool-search.json"
    if [ ! -e "$cfg" ]; then
      mkdir -p "$(dirname "$cfg")"
      cat > "$cfg" <<'EOF'
{
  "version": 1,
  "scope": "user",
  "groups": [
    { "name": "browser", "prefixes": ["mcp__agent-browser-fast__", "mcp__agent-browser-vision__"] },
    { "name": "docs", "prefixes": ["mcp__docforge__"] },
    { "name": "web", "tools": ["web_fetch", "web_search", "read_page", "x_search"] },
    { "name": "session", "prefixes": ["session_", "schedule_", "terminal_", "subagent", "send_message", "interrupt_agent", "list_agents", "list_subagent_models"] },
    { "name": "goal", "tools": ["create_goal", "get_goal", "update_goal"] }
  ]
}
EOF
    fi
  '';

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
      # agent-browser CLI skill 默认用 Edge，避免它去找未安装的 Chrome。
      export AGENT_BROWSER_ENGINE="chrome"
      export AGENT_BROWSER_EXECUTABLE_PATH="${lib.getExe pkgs.microsoft-edge}"
      # dsh-our-free-model 的 OpenCode 免费车道需要本地 Bun。
      export OUR_FREE_MODEL_BUN="${pkgs.bun}/bin/bun"
      exec dsh "$@"
    '')
  ];
}
