{
  description = "My XPS 15 9530 NixOS Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    zenBrowser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # My Config files
    lazyvim-config = {
      url = "github:LikelyLucid/lazyvim-dotfiles";
      flake = false;
      };

    dotfiles = {
      url = "github:LikelyLucid/dotfiles";
      flake = false;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl.url = "github:nix-community/nixos-wsl";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, zenBrowser, lazyvim-config, dotfiles, sops-nix, nixos-wsl, ... }: {
    nixosConfigurations.artsxps = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixos-hardware.nixosModules.dell-xps-15-9530
        ./hosts/artsxps/configuration.nix
        sops-nix.nixosModules.sops
        ./modules/secrets.nix
        home-manager.nixosModules.home-manager
        ({ config, pkgs, ... }: {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            sharedModules = [ sops-nix.homeManagerModules.sops ];
            extraSpecialArgs = { inherit zenBrowser lazyvim-config dotfiles; };
            users.lucid = import ./home.nix;
          };
        })
      ];
      specialArgs = { inherit zenBrowser lazyvim-config dotfiles; };
    };

    nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nixos-wsl.nixosModules.wsl
        ./hosts/wsl/configuration.nix
        sops-nix.nixosModules.sops
        ./modules/secrets.nix
        home-manager.nixosModules.home-manager
        ({ config, pkgs, ... }: {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            sharedModules = [ sops-nix.homeManagerModules.sops ];
            extraSpecialArgs = { inherit lazyvim-config dotfiles; };
            users.lucid = import ./hosts/wsl/home.nix;
          };
        })
      ];
      specialArgs = { inherit lazyvim-config dotfiles; };
    };
  };
}

