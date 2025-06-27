{ config, pkgs, zenBrowser, lazyvim-config, ... }:
{
  imports = [
    ./modules/window-manager/hyprland-config.nix
    ./modules/dev/developer.nix
    ./modules/notes/notes.nix
    ./modules/browsers/browsers.nix
  ];

  home.username = "lucid";
  home.homeDirectory = "/home/lucid";

  home.packages = with pkgs; [
    hyprpaper
    waybar
    kitty
    rofi-wayland
    cava
    wallust
    spotify-player
    fastfetch
  ];

  home.stateVersion = "23.05";

  }
