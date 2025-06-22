{ config, pkgs, ... }:
{
  # services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.wayland.enable = true;
  services.xserver.desktopManager.plasma6.enable = true;

  xdg.portal.enable = true;
  # services.libinput.touchpad.naturalScrolling;
}
