{
  description = "NixOS configuration";
  inputs = {
    nixpkgs.url = "git+https://mirrors.nju.edu.cn/git/nixpkgs.git?ref=nixos-unstable&shallow=1";
    home-manager = {
      url = "git+https://gh-proxy.com/github.com/nix-community/home-manager/";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "git+https://gh-proxy.com/github.com/noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "git+https://gh-proxy.com/github.com/danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
  let
    userSettings = {
      username = "zxcfdcmv";
      email = "zxcfdcmv@foxmail.com";
      hostName = "nixos";
      dotfilesDir = "/home/zxcfdcmv/nixos";
    };
  in
  {
    nixosConfigurations = {
      ${userSettings.hostName} = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit (inputs) noctalia stylix;
          inherit userSettings;
        };
        modules = [
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
                inherit (inputs) noctalia;
                inherit userSettings;
              };
            };
          }
        ];
      };
    };
  };
}
