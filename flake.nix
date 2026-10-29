# flake.nix
{
  description = "NixOS configuration";
  inputs = {
    nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";
    home-manager = {
      url = "git+https://gh-9pj.pages.dev/github.com/nix-community/home-manager/?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # noctalia = {
    #   url = "git+https://gh-proxy.org/github.com/noctalia-dev/noctalia-shell/?shallow=1";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
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
    harbor = {
      url = "git+https://gh-9pj.pages.dev/github.com/axioncs/harbor-flake?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    purple = {
      url = "git+https://gh-9pj.pages.dev/github.com/erickochen/purple?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs"; # 官方建议，避免引入第二份 nixpkgs
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
          inherit (inputs) stylix nix-flatpak nix-cachyos-kernel obsidian-extensions driftwm;
          inherit userSettings;
        };
        modules = [
          { nixpkgs.overlays = [ inputs.obsidian-extensions.overlays.default ]; }
          ./configuration.nix
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
                inherit (inputs) steam-config-nix mark-shot harbor purple;
                inherit userSettings;
              };
            };
          }
        ];
      };
    };
  };
}
