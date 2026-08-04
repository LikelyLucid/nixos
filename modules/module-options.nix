{
  config,
  inputs,
  lib,
  ...
}:
{
  options =
    let
      policy = builtins.fromJSON (builtins.readFile ../dendritic-policy.json);
      deferred_module_options =
        kind: groups:
        lib.genAttrs groups (
          name:
          lib.mkOption {
            type = lib.types.deferredModule;
            default = { };
            description = "${kind} deferred module group `${name}`.";
          }
        );
      host_options = lib.mapAttrs (
        _: _:
        lib.mkOption {
          type = lib.types.submodule {
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
          };
          default = { };
        }
      ) policy.hosts;
    in
    {
      homeManager.modules = deferred_module_options "Home Manager" policy.homeManagerModuleGroups;
      nixos.modules = deferred_module_options "NixOS" policy.nixosModuleGroups;
      nixos.configurations = host_options;
    };

  config.flake.nixosConfigurations = lib.mapAttrs (
    _: host:
    inputs.nixpkgs.lib.nixosSystem {
      inherit (host) system modules;
    }
  ) config.nixos.configurations;
}
