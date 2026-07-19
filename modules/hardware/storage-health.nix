{ ... }:
{
  nixos.modules.desktop =
    { pkgs, ... }:
    {
      services.smartd.enable = true;
      environment.systemPackages = [ pkgs.nvme-cli ];
    };
}
