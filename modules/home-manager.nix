{
  config,
  inputs,
  ...
}:
{
  nixos.modules.common = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "backup";
      sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];
      users.lucid.imports = [ config.homeManager.modules.common ];
    };
  };

  nixos.modules.desktop = {
    home-manager.users.lucid.imports = [ config.homeManager.modules.desktop ];
  };

  nixos.modules.wsl = {
    home-manager.users.lucid.imports = [ config.homeManager.modules.wsl ];
  };
}
