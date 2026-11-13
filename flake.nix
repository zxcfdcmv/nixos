# flake.nix
{
  description = "NixOS configuration";
  inputs = {
    nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";
    home-manager = {
      url = "git+https://gh-9pj.pages.dev/github.com/nix-community/home-manager/?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "git+https://gh-9pj.pages.dev/github.com/danth/stylix/?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak = {
      url = "git+https://gh-9pj.pages.dev/github.com/gmodena/nix-flatpak?shallow=1";
    };
    nix-cachyos-kernel = {
      url = "git+https://gh-9pj.pages.dev/github.com/xddxdd/nix-cachyos-kernel.git?ref=release&shallow=1";
    };
    disko = {
      url = "git+https://gh-9pj.pages.dev/github.com/nix-community/disko?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    steam-config-nix = {
      url = "git+https://gh-9pj.pages.dev/github.com/different-name/steam-config-nix?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    obsidian-extensions = {
      url = "git+https://gh-9pj.pages.dev/github.com/karaolidis/nix-obsidian-extensions?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    driftwm = {
      url = "git+https://gh-9pj.pages.dev/github.com/malbiruk/driftwm?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mark-shot = {
      url = "git+https://gh-9pj.pages.dev/github.com/jswysnemc/mark-shot?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    purple = {
      url = "git+https://gh-9pj.pages.dev/github.com/erickochen/purple?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agent-skills = {
      url = "git+https://gh.wha1e.dpdns.org/github.com/Kyure-A/agent-skills-nix?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deepseek-harness = {
      url = "git+https://gh.wha1e.dpdns.org/github.com/Moraxyc/deepseek-harness.nix?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    anthropic-skills = {
      url = "git+https://gh.wha1e.dpdns.org/github.com/anthropics/skills?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      flake = false;
    };
    find-skills = {
      url = "git+https://gh.wha1e.dpdns.org/github.com/vercel-labs/skills?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      flake = false;
    };
    mattpocock-skills = {
      url = "git+https://gh.wha1e.dpdns.org/github.com/mattpocock/skills?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      flake = false;
    };
    agent-browser = {
      url = "git+https://gh.wha1e.dpdns.org/github.com/vercel-labs/agent-browser?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
  let
    proxySettings = {
      # githubProxy = "https://gh-proxy.org";
      githubProxy = "https://gh-9pj.pages.dev";
      # 未来可以轻松切换，比如：
      # githubProxy = "https://mirror.ghproxy.com";
      # githubProxy = "";  # 直接访问
    };
    userSettings = {
      username = "zxcfdcmv";
      email = "zxcfdcmv@foxmail.com";
      hostName = "nixos";
      dotfilesDir = "/home/zxcfdcmv/nixos";
      account_id = "4d1d805f3220db22010d364de7ae8343";
      gateway = "ai-router";
      inherit (proxySettings) githubProxy;
    };
    system = "x86_64-linux";
  in
  {
    nixosConfigurations = {
      ${userSettings.hostName} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit (inputs) stylix nix-flatpak nix-cachyos-kernel obsidian-extensions driftwm;
          inherit userSettings;
        };
        modules = [
          {
            nixpkgs.overlays = [
              inputs.obsidian-extensions.overlays.default
              inputs.deepseek-harness.overlays.default
            ];
          }
          ./configuration.nix
          inputs.disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              users.${userSettings.username} = {
                imports = [
                  ./home.nix
                ];
              };
              extraSpecialArgs = {
                inherit inputs;
                inherit (inputs) steam-config-nix mark-shot purple;
                inherit userSettings;
              };
            };
          }
        ];
      };
    };
  };
}
