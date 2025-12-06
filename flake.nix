{
  description = "NixOS configuration";

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";
    home-manager = {
      url = "git+https://gh-proxy.com/github.com/nix-community/home-manager/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # sbsrf-plum = {
    #   url = "git+https://gh-proxy.com/github.com/sbsrf/sbsrf";
    #   flake = false;
    # };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:{
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.zxcfdcmv = import ./home.nix;
              extraSpecialArgs = {
                sbsrf-plum = inputs.sbsrf-plum;
              };
            };
          }
        ];
      };
    };
  };
}
