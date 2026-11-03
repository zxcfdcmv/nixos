{ config, pkgs, lib, inputs, userSettings, ... }:
{
  imports = [ inputs.agent-skills.homeManagerModules.default ];

  home.packages = with pkgs; [
    # playwright-mcp
    agent-browser
    uv
    nodejs
    opencode
    obscura
  ];

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
            command = "${pkgs.opencode}/bin/opencode";
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
              ];
            };
          };
          open_router = {
            api_url = "https://gateway.ai.cloudflare.com/v1/${userSettings.account_id}/${userSettings.gateway}/openrouter";
            available_models = [
              {
                name = "openrouter/free";
                display_name = "OpenRouter Free Router";
                max_tokens = 131072;
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

        deepseek-visionary = {
          command = lib.getExe' pkgs.nodejs "npx";
          args = [
            "-y"
            "@xlight-oss/visionary-server"
            "mcp-stdio"
          ];
        };

        ripgrep = {
          command = lib.getExe' pkgs.uv "uvx";
          args = [ "mcp-server-ripgrep" ];
        };

        # playwright = {
        #   command = lib.getExe pkgs.playwright-mcp;
        #   args = [ "--caps" "vision" ];
        # };

        agent-browser-fast = {
          command = lib.getExe pkgs.agent-browser;
          args = [ 
            "mcp" 
            "--engine" "obscura"
            "--executable-path" "${lib.getExe pkgs.obscura}"
            "--headless"
          ];
        };

        agent-browser-vision = {
          command = lib.getExe pkgs.agent-browser;
          args = [ 
            "mcp" 
            "--engine" "chrome"
            "--executable-path" "${lib.getExe pkgs.microsoft-edge}"
            "--headless"
          ];
        };

        memory = {
          command = lib.getExe' pkgs.nodejs "npx";
          args = [ "-y" "@modelcontextprotocol/server-memory" ];
        };

        git = {
          command = lib.getExe' pkgs.uv "uvx";
          args = [ "mcp-server-git" ];
        };

        docker = {
          command = lib.getExe' pkgs.nodejs "npx";
          args = [ "-y" "@modelcontextprotocol/server-docker" ];
        };
      };
    };
  };
}
