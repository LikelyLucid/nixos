{ config, pkgs, zenBrowser, ... }:
{
  imports = [
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
  ];

  home.stateVersion = "23.05";
}
