{ config, pkgs, lib, inputs, userSettings, ... }:
let
  # Obscura 不支持 proxy bypass：只要 NO_PROXY / no_proxy /
  # AGENT_BROWSER_PROXY_BYPASS 存在（哪怕是空值）就会拒绝启动。
  # 在包装器里先 unset，再 exec agent-browser。
  # agentBrowserObscura = pkgs.writeShellScript "agent-browser-obscura" ''
  #   unset NO_PROXY no_proxy AGENT_BROWSER_PROXY_BYPASS
  #   exec ${lib.getExe pkgs.agent-browser} "$@"
  # '';
in
{
  imports = [ inputs.agent-skills.homeManagerModules.default ];

  home.packages = with pkgs; [
    # playwright-mcp
    agent-browser
    uv
    nodejs
    bun
    # obscura
    # mcp-ripgrep（npm）运行时需要 PATH 里有 rg
    ripgrep
  ];

  # agent-browser CLI 默认用 Edge；MCP server 里的 AGENT_BROWSER_ENGINE
  # 会覆盖这里（fast 用 obscura，vision 用 chrome+Edge）。
  home.sessionVariables = {
    AGENT_BROWSER_ENGINE = "chrome";
    AGENT_BROWSER_EXECUTABLE_PATH = lib.getExe pkgs.microsoft-edge;
    # dsh-our-free-model 的 OpenCode 免费车道需要本地 Bun。
    OUR_FREE_MODEL_BUN = "${pkgs.bun}/bin/bun";
  };

  programs = {
    agent-skills = {
      enable = true;
      sources = {
        anthropic = {
          input = "anthropic-skills";
          subdir = "skills";
        };
        find-skills = {
          input = "find-skills";
          subdir = "skills";
        };
        agent-browser = {
          input = "agent-browser";
          subdir = "skills";
        };
        mattpocock-productivity = {
          input = "mattpocock-skills";
          subdir = "skills/productivity";
        };
        mattpocock-engineering = {
          input = "mattpocock-skills";
          subdir = "skills/engineering";
        };
      };
      skills.enable = [
        # anthropic
        "docx"
        "pdf"
        "xlsx"
        "pptx"
        "skill-creator"

        # vercel-labs
        "find-skills"
        "agent-browser"

        # mattpocock
        "grill-me"
        "grilling"
        "handoff"
        "grill-with-docs"
        "wait-what"
        "diagnosing-bugs"
        "wizard"
        "tdd"
        "wayfinder"
        "to-spec"
        "writing-for-agents"
        "triage"
      ];
      targets.agents.enable = true;
    };

    zed-editor = {
      enable = true;
      enableMcpIntegration = true;
      extensions = [
        "nix"
        "sql"
        "html"
        "toml"
      ];
      userSettings = {
        # ui_font_family = "Maple Mono NF CN";
        ui_font_size = lib.mkForce 16;
        # buffer_font_family = "Maple Mono NF CN";
        buffer_font_size = lib.mkForce 16;
        # theme = {
        #   mode = "system";
        #   dark = "one Dark";
        #   light = "one Light";
        # };
        terminal = {
          env = { TERM = "footclient"; };
          # font_family = "Maple Mono NF CN";
          # font_size = 16;
          shell = "system";
        };
        autosave = "on_focus_change";
        load_direnv = "shell_hook";
        telemetry = {
          diagnostics = false;
          metrics = false;
        };
        agent_servers = {
          "OpenCode (Nix)" = {
            command = "${config.programs.opencode.package}/bin/opencode";
            args = [ "acp" ];
            type = "custom";
          };
        };
        agent = {
          favorite_models = [
            {
              provider = "openrouter";
              model = "openrouter/free";
            }
            {
              provider = "cf_gateway";
              model = "google-ai-studio/gemini-3.8-flash";
            }
            {
              provider = "cf_gateway";
              model = "custom-glm/glm-4.7-flash";
            }
            {
              provider = "cf_gateway";
              model = "custom-nov/glm-4.7-flash";
            }
            {
              provider = "cf_gateway";
              model = "custom-nv/z-ai/glm-5.3-flash";
            }
            {
              provider = "cf_gateway";
              model = "custom-nv/deepseek-ai/deepseek-v4.1-flash";
            }
            {
              provider = "cf_gateway";
              model = "custom-nv/openai/gpt-oss-20b";
            }
            {
              provider = "cf_gateway";
              model = "custom-nv/nvidia/nemotron-3-ultra-550b-a55b";
            }
            {
              provider = "cf_gateway";
              model = "custom-nv/google/gemma-4-31b-it";
            }
            {
              provider = "cf_gateway";
              model = "custom-nv/minimaxai/minimax-m3.1-flash";
            }
          ];
        };
        language_models = {
          openai_compatible = {
            cf_gateway = {
              api_url = "https://gateway.ai.cloudflare.com/v1/${userSettings.account_id}/${userSettings.gateway}/compat";
              available_models = [
                {
                  name = "google-ai-studio/gemini-3.8-flash";
                  display_name = "Gemini 3.8 Flash";
                  max_tokens = 1048576;
                }
                {
                  name = "google-ai-studio/gemini-3.5-flash";
                  display_name = "Gemini 3.5 Flash";
                  max_tokens = 1048576;
                }
                {
                  name = "google-ai-studio/gemini-3.5-flash-lite";
                  display_name = "Gemini 3.5 Flash-Lite";
                  max_tokens = 1048576;
                }
                {
                  name = "google-ai-studio/gemini-3.6-flash";
                  display_name = "Gemini 3.6 Flash";
                  max_tokens = 1048576;
                }
                {
                  name = "google-ai-studio/gemini-3.1-flash-lite";
                  display_name = "Gemini 3.1 Flash-Lite";
                  max_tokens = 1048576;
                }
                {
                  name = "custom-glm/glm-4-flash-250414";
                  display_name = "GLM 4 Flash(glm)";
                  max_tokens = 131072;
                }
                {
                  name = "custom-glm/glm-4.5-flash";
                  display_name = "GLM 4.5 Flash(glm)";
                  max_tokens = 131072;
                }
                {
                  name = "custom-glm/glm-4.7-flash";
                  display_name = "GLM 4.7 Flash(glm)";
                  max_tokens = 200000;
                }
                {
                  name = "custom-glm/glm-5.3";
                  display_name = "GLM-5.3 pro(glm)";
                  max_tokens = 131072;
                }
                {
                  name = "custom-nov/glm-4.7-flash";
                  display_name = "GLM 4.7 Flash(nov)";
                  max_tokens = 200000;
                }
                {
                  name = "custom-nov/glm-4.6v-flash";
                  display_name = "GLM 4.6v Flash(nov)";
                  max_tokens = 128000;
                }
                {
                  name = "custom-nov/glm-4.1v-thinking-flash";
                  display_name = "GLM 4.1v thinking Flash(nov)";
                  max_tokens = 128000;
                }
                {
                  name = "custom-nv/z-ai/glm-5.3-flash";
                  display_name = "GLM 5.3 Flash(Nvidia)";
                  max_tokens = 1048576;
                }
                {
                  name = "custom-nv/deepseek-ai/deepseek-v4.1-flash";
                  display_name = "DeepSeek 4.1 Flash(Nvidia)";
                  max_tokens = 1048576;
                }
                {
                  name = "custom-nv/minimaxai/minimax-m3.1-flash";
                  display_name = "MiniMax m3.1 Flash(Nvidia)";
                  max_tokens = 1048576;
                }
                {
                  name = "custom-nv/openai/gpt-oss-20b";
                  display_name = "GPT OSS 20b(Nvidia)";
                  max_tokens = 1048576;
                }
                {
                  name = "custom-nv/nvidia/nemotron-3-ultra-550b-a55b";
                  display_name = "Nemotron 3 ltra 550b a55b(Nvidia)";
                  max_tokens = 1048576;
                }
                {
                  name = "custom-nv/nvidia/nemotron-3-super-120b-a12b";
                  display_name = "Nemotron 3 super 120b a12b(Nvidia)";
                  max_tokens = 1048576;
                }
                {
                  name = "custom-nv/google/gemma-4-31b-it";
                  display_name = "Google Gemma 4 31b it(Nvidia)";
                  max_tokens = 1048576;
                }
                {
                  name = "custom-nv/meta/llama-3.2-90b-vision-instruct";
                  display_name = "llama 3.2 90b(Nvidia)";
                  max_tokens = 1048576;
                }
                {
                  name = "custom-nv/google/diffusiongemma-26b-a4b-it";
                  display_name = "Google Diffusiongemma 26b a4b(Nvidia)";
                  max_tokens = 1048576;
                }
                {
                  name = "custom-sen/sensenova-6.8-flash";
                  display_name = "Sensenova 6.8 flash";
                  max_tokens = 1048576;
                }
                {
                  name = "custom-sen/sensenova-6.8-flash-lite";
                  display_name = "Sensenova 6.8 flash lite";
                  max_tokens = 1048576;
                }
                {
                  name = "custom-sen/deepseek-v4-flash";
                  display_name = "deepseek v4 flash(sensenova)";
                  max_tokens = 1048576;
                }
                {
                  name = "custom-sen/deepseek-flash";
                  display_name = "deepseek v4.1 flash(sensenova)";
                  max_tokens = 1048576;
                }
                {
                  name = "custom-sen/glm-5.2";
                  display_name = "GLM 5.2(sensenova)";
                  max_tokens = 1048576;
                }
                {
                  name = "custom-sen/kimi-k3";
                  display_name = "Kimi k3(sensenova)";
                  max_tokens = 1048576;
                }
              ];
            };
          };
          open_router = {
            api_url = "https://gateway.ai.cloudflare.com/v1/${userSettings.account_id}/${userSettings.gateway}/openrouter";
            available_models = [
              {
                name = "openrouter/free";
                display_name = "OpenRouter Free Router";
                max_tokens = 1048576;
              }
            ];
          };
        };
      };
      mutableUserSettings = true;
    };

    mcp = {
      enable = true;
      servers = {
        docforge = {
          command = lib.getExe' pkgs.uv "uvx";
          args = [ "docforge-mcp" ];
        };

        # PyPI 上没有 mcp-server-ripgrep；改用 npm 的 mcp-ripgrep。
        ripgrep = {
          command = lib.getExe' pkgs.nodejs "npx";
          args = [ "-y" "mcp-ripgrep" ];
        };

        # playwright = {
        #   command = lib.getExe pkgs.playwright-mcp;
        #   args = [ "--caps" "vision" ];
        # };

        # agent-browser mcp 只接受 --tools / --config，不认 --engine、
        # --executable-path、--headless；引擎和可执行文件走环境变量，
        # 默认就是 headless（要显示窗口才用 --headed / AGENT_BROWSER_HEADED）。
        # agent-browser-fast = {
        #   # command 的类型是 nullOr str，这里必须把 derivation 转成 store 路径字符串
        #   command = "${agentBrowserObscura}";
        #   args = [ "mcp" ];
        #   env = {
        #     AGENT_BROWSER_ENGINE = "obscura";
        #     AGENT_BROWSER_EXECUTABLE_PATH = lib.getExe pkgs.obscura;
        #   };
        # };

        agent-browser-vision = {
          command = lib.getExe pkgs.agent-browser;
          args = [ "mcp" ];
          env = {
            AGENT_BROWSER_ENGINE = "chrome";
            AGENT_BROWSER_EXECUTABLE_PATH = lib.getExe pkgs.microsoft-edge;
          };
        };

        # 不指定 MEMORY_FILE_PATH 时，server-memory 会把知识图谱写进
        # npx 缓存目录里的 node_modules，清缓存/升级就会丢数据。
        memory = {
          command = lib.getExe' pkgs.nodejs "npx";
          args = [ "-y" "@modelcontextprotocol/server-memory" ];
          env = {
            MEMORY_FILE_PATH = "${config.home.homeDirectory}/.local/share/zed/memory.jsonl";
          };
        };

      };
    };

  };
}
