{ config, pkgs, lib, inputs, userSettings, ... }:
let
  # CF AI Gateway 的模型 / 动态路由定义（ai.nix、opencode.nix、dsh.nix 共用）。
  cf = import ./cf-models.nix { inherit lib; };
  cfFavoriteModels =
    map (model: { provider = "cf_gateway"; model = model.id; }) cf.models
    ++ [ { provider = "openrouter"; model = "openrouter/free"; } ];
  cfAvailableModels = map (model: {
    name = model.id;
    display_name = model.name;
    max_tokens = model.context;
  }) cf.models;

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
    # 任意文档 → Markdown（读取 PDF/Office/EPUB 等）
    markitdown
    # Markdown ↔ docx/pptx/pdf 转换
    pandoc
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

  # uv/uvx 默认从 files.pythonhosted.org 下载 wheel，这个 CDN 在国内经常
  # 只有几 KB/s 甚至连接超时。固定清华镜像后 docforge MCP 首次解析/下载
  # 也能在几秒内完成。
  xdg.configFile."uv/uv.toml".text = ''
    [[index]]
    url = "https://pypi.tuna.tsinghua.edu.cn/simple"
    default = true
  '';

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
        "go"
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
        # Go：用 nixpkgs 里的 gopls，别让扩展自己下载一份
        lsp = {
          gopls = {
            binary.path = "${pkgs.gopls}/bin/gopls";
            initialization_options = {
              usePlaceholders = true;
              completeUnimported = true;
              # staticcheck 已经由 golangci-lint 跑，gopls 这边开诊断即可
              staticcheck = true;
            };
          };
        };
        languages = {
          Go = {
            format_on_save = "on";
            formatter = "language_server";
            hard_tabs = true;
          };
        };
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
          favorite_models = cfFavoriteModels;
        };
        language_models = {
          openai_compatible = {
            cf_gateway = {
              api_url = "https://gateway.ai.cloudflare.com/v1/${userSettings.account_id}/${userSettings.gateway}/compat";
              available_models = cfAvailableModels;
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

        # PyPI 上没有 mcp-server-ripgrep；改用 npm 的 mcp-ripgrep。
        ripgrep = {
          command = lib.getExe' pkgs.nodejs "npx";
          args = [ "-y" "mcp-ripgrep" ];
        };

        # 公共远程 MCP（Streamable HTTP），都无需认证。注意 home-manager 的
        # toOpencodeShape 会丢掉自由字段（如 oauth = false），这里写了也不生效；
        # 实测两者直接 connected，不会强行走 OAuth。
        context7 = {
          url = "https://mcp.context7.com/mcp";
        };

        deepwiki = {
          url = "https://mcp.deepwiki.com/mcp";
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
