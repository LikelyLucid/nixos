{ pkgs, lazyvim-config, lib, dotfiles, ... }:
{
 services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      preload = "${dotfiles}/media/wallpapers/Wallpaper 4.jpg";
      wallpaper = ",${dotfiles}/media/wallpapers/Wallpaper 4.jpg";
      };
  };
  wayland.windowManager.hyprland.extraConfig = "exec-once = hyprpaper &";

  services.playerctld.enable = true;

  programs.hyprlock.enable = true;
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "hyprlock";
        before_sleep_cmd = "hyprlock";
      };

      listener = [
        {
          timeout = 300;
          on-timeout = "hyprlock";
        }
        {
          timeout = 600;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

}
