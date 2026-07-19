{ ... }:
{
  nixos.modules.desktop = {
    services.gvfs.enable = true;
    services.udisks2.enable = true;
  };

  homeManager.modules.desktop.services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
    tray = "auto";
  };
}
