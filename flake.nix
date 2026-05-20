{
  description = "My XPS 15 9530 NixOS Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    zenBrowser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    lazyvim-config = {
      url = "github:LikelyLucid/lazyvim-dotfiles";
      flake = false;
    };

    dotfiles = {
      url = "github:LikelyLucid/dotfiles";
      flake = false;
    };

    pi-config = {
      url = "github:LikelyLucid/pi-config";
      flake = false;
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl.url = "github:nix-community/nixos-wsl";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    pi.url = "github:lukasl-dev/pi.nix";

    sopswarden = {
      url = "github:pfassina/sopswarden";
    };
  };

  outputs = inputs@{
    self,
    nixpkgs,
    nixos-hardware,
    home-manager,
    zenBrowser,
    lazyvim-config,
    dotfiles,
    pi-config,
    sops-nix,
    nixos-wsl,
    pi,
    sopswarden,
  }:
    let
      inherit (nixpkgs.lib) nixosSystem;

      common_special_args = {
        inherit lazyvim-config dotfiles pi-config;
        isWsl = false;
      };

      mkHomeManagerModule = {
        user_module,
        extra_special_args ? { },
      }:
        ({ ... }:
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              sharedModules = [ sops-nix.homeManagerModules.sops ];
              extraSpecialArgs = common_special_args // extra_special_args;
              users.lucid = import user_module;
            };
          }
        );

      mkHost = {
        modules,
        home_module,
        system ? "x86_64-linux",
        extra_special_args ? { },
      }:
        nixosSystem {
          inherit system;
          specialArgs = common_special_args // extra_special_args;
          modules =
            modules
            ++ [
              { nixpkgs.overlays = [ pi.overlays.default ]; }
              home-manager.nixosModules.home-manager
              home_module
            ];
        };
    in {
      nixosConfigurations.artsxps = mkHost {
        modules = [
          nixos-hardware.nixosModules.dell-xps-15-9530
          sops-nix.nixosModules.sops
          ./hosts/artsxps/configuration.nix
          ./modules/secrets.nix
          ./modules/bitwarden-secrets.nix
        ];
        home_module = mkHomeManagerModule {
          user_module = ./home.nix;
          extra_special_args = { inherit zenBrowser; };
        };
        extra_special_args = { inherit zenBrowser; };
      };

      nixosConfigurations.wsl = mkHost {
        modules = [
          nixos-wsl.nixosModules.wsl
          ./modules/bitwarden-secrets.nix
          ./hosts/wsl/configuration.nix
        ];
        home_module = mkHomeManagerModule {
          user_module = ./home.nix;
          extra_special_args = { isWsl = true; };
        };
        extra_special_args = { isWsl = true; };
      };
    };
}
