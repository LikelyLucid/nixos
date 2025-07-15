{ pkgs, lazyvim-config, lib, dotfiles, ... }:
{
 services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      preload = config.wallpaper;
      wallpaper = ",${config.wallpaper}";
      };
  };
  wayland.windowManager.hyprland.extraConfig = "exec-once = hyprpaper &";

  services.playerctld.enable = true;

  environment.systemPackages = with pkgs; [
    wallust
  ];
}
