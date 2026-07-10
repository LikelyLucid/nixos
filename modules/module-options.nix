{
  config,
  inputs,
  lib,
  ...
}:
{
  options = {
    homeManager.modules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
      description = "Home Manager modules composed by top-level feature modules.";
    };

    nixos.modules = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = { };
      description = "NixOS modules composed by top-level feature modules.";
    };

    nixos.configurations = lib.mkOption {
      type = lib.types.lazyAttrsOf (
        lib.types.submodule {
          options = {
            system = lib.mkOption {
              type = lib.types.str;
              default = "x86_64-linux";
            };

            modules = lib.mkOption {
              type = lib.types.listOf lib.types.deferredModule;
              default = [ ];
            };
          };
        }
      );
      default = { };
      description = "NixOS systems produced by the top-level configuration.";
    };
  };

  config.flake.nixosConfigurations = lib.mapAttrs (
    _: host:
    inputs.nixpkgs.lib.nixosSystem {
      inherit (host) system modules;
    }
  ) config.nixos.configurations;
}
