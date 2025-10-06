{ pkgs, dotfiles, ... }:
let
  wallpaper_path = "${dotfiles}/media/wallpapers/Wallpaper 4.jpg";
in {
  ############################################
  # HYPRPAPER
  ############################################
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      preload = wallpaper_path;
      wallpaper = ",${wallpaper_path}";
    };
  };

  ############################################
  # HYPRLAND SESSION HELPERS
  ############################################
  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = hyprpaper &
  '';

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
