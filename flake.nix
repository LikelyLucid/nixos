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

    codex-desktop-linux.url = "github:ilysenko/codex-desktop-linux";

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium-browser = {
      url = "github:schembriaiden/helium-browser-nix-flake";
    };

    hyprland-canvas = {
      url = "github:zyrophix/hyprland-canvas";
      flake = false;
    };

  };

  outputs =
    {
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
      codex-desktop-linux,
      codex-cli-nix,
      helium-browser,
      hyprland-canvas,
      ...
    }:
    let
      inherit (nixpkgs.lib) nixosSystem;

      pyPkgs = nixpkgs.legacyPackages.x86_64-linux.python3Packages;
      hyprland-canvas-pkg = pyPkgs.buildPythonPackage {
        pname = "hyprland-canvas";
        version = "1.0.1";
        src = hyprland-canvas;
        format = "pyproject";
        nativeBuildInputs = [ pyPkgs.hatchling ];
        propagatedBuildInputs = [ pyPkgs.pyyaml ];
        doCheck = false;
      };

      common_special_args = {
        inherit lazyvim-config dotfiles pi-config;
        inherit hyprland-canvas-pkg;
        isWsl = false;
      };

      mkHomeManagerModule =
        {
          user_module,
          extra_special_args ? { },
          sharedModules ? [ ],
        }:
        (
          { ... }:
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              sharedModules = [ sops-nix.homeManagerModules.sops ] ++ sharedModules;
              extraSpecialArgs = common_special_args // extra_special_args;
              users.lucid = import user_module;
            };
          }
        );

      mkHost =
        {
          modules,
          home_module,
          system ? "x86_64-linux",
          extra_special_args ? { },
        }:
        nixosSystem {
          inherit system;
          specialArgs = common_special_args // extra_special_args;
          modules = modules ++ [
            {
              nixpkgs.overlays = [
                pi.overlays.default
                (final: prev: {
                  helium = helium-browser.packages.${prev.stdenv.hostPlatform.system}.helium;
                  cua-driver = prev.stdenv.mkDerivation {
                    pname = "cua-driver";
                    version = "0.6.8";
                    src = prev.fetchurl {
                      url = "https://github.com/trycua/cua/releases/download/cua-driver-rs-v0.6.8/cua-driver-rs-0.6.8-linux-x86_64-binary.tar.gz";
                      hash = "sha256-3ohcatgrXhDtAhO+RkLdp0tZIpkK1gAutbxIHV2JwFs=";
                    };
                    nativeBuildInputs = [ prev.autoPatchelfHook ];
                    buildInputs = [
                      prev.stdenv.cc.cc.lib
                      prev.libx11
                      prev.libxi
                    ];
                    dontUnpack = true;
                    installPhase = ''
                      tar -xzf $src
                      install -m755 -D cua-driver $out/bin/cua-driver
                    '';
                  };
                })
              ];
            }
            ./modules/nix-caches.nix
            home-manager.nixosModules.home-manager
            home_module
          ];
        };
    in
    {
      nixosConfigurations.artsxps = mkHost {
        modules = [
          nixos-hardware.nixosModules.dell-xps-15-9530
          sops-nix.nixosModules.sops
          codex-desktop-linux.nixosModules.default
          ./hosts/artsxps/configuration.nix
          ./modules/secrets.nix
          ./modules/bitwarden-secrets.nix
        ];
        home_module = mkHomeManagerModule {
          user_module = ./home.nix;
          extra_special_args = { inherit zenBrowser; };
        };
        extra_special_args = { inherit zenBrowser codex-cli-nix; };
      };

      nixosConfigurations.nixos-wsl = mkHost {
        modules = [
          nixos-wsl.nixosModules.wsl
          ./hosts/wsl/configuration.nix
        ];
        home_module = mkHomeManagerModule {
          user_module = ./home.nix;
          extra_special_args = {
            isWsl = true;
          };
        };
        extra_special_args = {
          isWsl = true;
        };
      };
    };
}
