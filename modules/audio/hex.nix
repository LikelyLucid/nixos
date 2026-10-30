{ inputs, ... }:
{
  nixos.modules.desktop = {
    imports = [ inputs.hex.nixosModules.hex ];
    programs.hex.enable = true;
  };

  homeManager.modules.desktop = {
    imports = [ inputs.hex.homeManagerModules.hex ];
    programs.hex = {
      enable = true;
      autostart = true;
    };
  };
}
