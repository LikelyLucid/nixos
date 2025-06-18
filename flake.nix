{
  description = "My XPS 15 9530 NixOS Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    zenBrowser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, zenBrowser, ... }: {
    nixosConfigurations.artsxps = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixos-hardware.nixosModules.dell-xps-15-9530
        ./configuration.nix
        home-manager.nixosModules.home-manager
        ({ config, pkgs, ... }: {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit zenBrowser; };
            users.lucid = import ./home.nix;
          };
        })
      ];
      specialArgs = { inherit zenBrowser; };
    };
  };
}

