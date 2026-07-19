{ ... }:
{
  nixos.modules.desktop =
    { pkgs, ... }:
    {
      services.colord.enable = true;
      environment.systemPackages = [ pkgs.gnome-color-manager ];
    };
}
