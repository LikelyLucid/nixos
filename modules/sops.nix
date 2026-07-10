{ inputs, ... }:
{
  nixos.modules.desktop.imports = [ inputs.sops-nix.nixosModules.sops ];
}
