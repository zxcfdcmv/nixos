{
  description = "NixOS configuration";
  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";
    home-manager = {
      url = "git+https://gh-proxy.com/github.com/nix-community/home-manager/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "git+https://gh-proxy.com/github.com/noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:{
    nixosConfigurations = {
      nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.zxcfdcmv = {
                imports = [
                  ./home.nix
                ];
              };
              extraSpecialArgs = {
                noctalia = inputs.noctalia;
              };
            };
          }
        ];
      };
    };
  };
}
