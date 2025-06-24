{ pkgs, lazyvim-config, lib, ... }:
{
 services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      preload = "~/dotfiles/media/wallpapers/Wallpaper 4.jpg";
      wallpaper = "/home/lucid/dotfiles/media/wallpapers/Wallpaper 4.jpg";
      };
  };
  wayland.windowManager.hyprland.extraConfig = "exec-once = hyprpaper &";
}
