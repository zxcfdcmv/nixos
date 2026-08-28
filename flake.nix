{
  description = "NixOS configuration";
  inputs = {
    nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";
    home-manager = {
      url = "git+https://gh-proxy.org/github.com/nix-community/home-manager/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # noctalia = {
    #   url = "git+https://gh-proxy.org/github.com/noctalia-dev/noctalia-shell";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    stylix = {
      url = "git+https://gh-proxy.org/github.com/danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak = {
      url = "git+https://gh-proxy.org/github.com/gmodena/nix-flatpak";
    };
    nix-cachyos-kernel = {
      url = "git+https://gh-proxy.org/github.com/xddxdd/nix-cachyos-kernel.git?ref=release";
    };
    steam-config-nix = {
      url = "git+https://gh-proxy.org/github.com/different-name/steam-config-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    obsidian-extensions = {
      url = "git+https://gh-proxy.org/github.com/karaolidis/nix-obsidian-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
  let
    proxySettings = {
      githubProxy = "https://gh-proxy.org";
      # 未来可以轻松切换，比如：
      # githubProxy = "https://mirror.ghproxy.com";
      # githubProxy = "";  # 直接访问
    };
    userSettings = {
      username = "zxcfdcmv";
      email = "zxcfdcmv@foxmail.com";
      hostName = "nixos";
      dotfilesDir = "/home/zxcfdcmv/nixos";
      inherit (proxySettings) githubProxy;
    };
    system = "x86_64-linux";
  in
  {
    nixosConfigurations = {
      ${userSettings.hostName} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit (inputs) stylix nix-flatpak nix-cachyos-kernel obsidian-extensions;
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
                inherit (inputs) steam-config-nix;
                inherit userSettings;
              };
            };
          }
        ];
      };
    };
  };
}
