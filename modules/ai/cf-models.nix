# Cloudflare AI Gateway 模型 / 动态路由的单一事实来源。
#
# ai.nix（Zed）、opencode.nix、dsh.nix 都从这里取模型，避免三份列表各改各的；
# cf-routes.nix 用 routeDefinitions 生成 REST API 请求体。
#
# 选型原则：只保留 2026-11-24 实测可用的模型，按“角色”而不是“跑分”排：
#   1. 快且常在线（NVIDIA NIM）
#   2. 质量 / 长上下文（Gemini Flash-Lite、GLM-5.3）
#   3. 跨供应商兜底（SenseNova）
#   4. 尾部（OpenRouter，额度账号级共享，放最后）
{ lib }:
let
  inherit (lib) imap0;

  # 动态路由成员。provider/model 是发给 CF AI Gateway 的上游标识；
  # 顺序即优先级，timeout 单位毫秒，retries 默认 0（避免层层重试把延迟叠爆）。
  routes = {
    free = {
      name = "free";
      displayName = "CF Free Route";
      # 取路由内所有成员上下文的最小值，声明大了会在真实模型处 400。
      context = 131072;
      vision = false;
      members = [
        {
          provider = "custom-nv";
          model = "nvidia/nemotron-3.5-lightning-30b-a3b";
        }
        {
          provider = "google-ai-studio";
          model = "gemini-3.5-flash-lite";
        }
        {
          provider = "custom-glm";
          model = "glm-5.3";
        }
        {
          provider = "custom-sen";
          model = "deepseek-flash";
        }
        {
          provider = "openrouter";
          model = "openrouter/free";
          timeout = 30000;
        }
      ];
    };

    vision = {
      name = "vision";
      displayName = "CF Vision Route";
      # glm-4.1v-thinking-flash 只有 128k。
      context = 128000;
      vision = true;
      members = [
        {
          provider = "custom-nv";
          model = "nvidia/nemotron-3.5-super-vl-120b-a12b";
          timeout = 20000;
        }
        {
          provider = "custom-nov";
          model = "glm-4.1v-thinking-flash";
        }
        {
          provider = "google-ai-studio";
          model = "gemini-3.5-flash-lite";
        }
      ];
    };

    long = {
      name = "long";
      displayName = "CF Long Context Route";
      # 三个成员都是 1M 上下文；只放真正需要长上下文的场景，平时用 free。
      context = 1048576;
      vision = false;
      members = [
        {
          provider = "google-ai-studio";
          model = "gemini-3.5-flash-lite";
        }
        {
          provider = "custom-glm";
          model = "glm-5.3";
        }
        {
          provider = "custom-sen";
          model = "deepseek-flash";
        }
      ];
    };
  };

  # 留给手动选择的“逃生舱”：路由整体抽风时可以直接点名。
  # 只放 3 个，避免又把列表堆回 26 条。
  named = [
    {
      id = "custom-nv/nvidia/nemotron-3.5-lightning-30b-a3b";
      name = "Nemotron 3.5 Lightning 30B (fast)";
      context = 131072;
      vision = false;
    }
    {
      id = "custom-nv/nvidia/nemotron-3-ultra-550b-a55b";
      name = "Nemotron 3 Ultra 550B";
      context = 131072;
      vision = false;
    }
    {
      id = "custom-glm/glm-5.3-flash";
      name = "GLM-5.3-Flash (1M)";
      context = 1048576;
      vision = false;
    }
  ];

  # 生成 CF 动态路由的 elements 数组：start -> m0 -> m1 ... -> end。
  # 每个 model 节点 success 直接结束，fallback 落到下一个；最后一个失败则结束并返回错误。
  mkElements = route:
    let
      members = route.members;
      last = builtins.length members - 1;
      nodeId = i: "m${toString i}";
      mkNode = i: member: {
        id = nodeId i;
        type = "model";
        properties = {
          provider = member.provider;
          model = member.model;
          timeout = member.timeout or 15000;
          retries = member.retries or 0;
        };
        outputs = {
          success = { elementId = "end"; };
          fallback = {
            elementId = if i == last then "end" else nodeId (i + 1);
          };
        };
      };
    in
    [
      {
        id = "start";
        type = "start";
        outputs.next.elementId = nodeId 0;
      }
    ]
    ++ imap0 mkNode members
    ++ [
      {
        id = "end";
        type = "end";
        outputs = { };
      }
    ];

  routeModels = map
    (route: {
      id = "dynamic/${route.name}";
      name = route.displayName;
      inherit (route) context vision;
    })
    (builtins.attrValues routes);
in
{
  inherit routes named;
  models = routeModels ++ named;
  # 直接就是 POST/PUT 请求体：{ free = { name = "free"; elements = [...]; }; ... }
  routeDefinitions = lib.mapAttrs
    (_: route: {
      inherit (route) name;
      elements = mkElements route;
    })
    routes;
}
