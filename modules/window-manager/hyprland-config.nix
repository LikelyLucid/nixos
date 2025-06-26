{ pkgs, lazyvim-config, lib, ... }:
{
 services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      preload = "~/dotfiles/media/wallpapers/Wallpaper 4.jpg";
      wallpaper = ",~/dotfiles/media/wallpapers/Wallpaper 4.jpg";
      };
  };
  wayland.windowManager.hyprland.extraConfig = "exec-once = hyprpaper &";

  services.playerctld.enable = true;

}
