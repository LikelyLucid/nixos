{ config, pkgs, ... }:
{
  home.username = "lucid";
  home.homeDirectory = "/home/lucid";

  home.packages = with pkgs; [
    firefox
    hyprpaper
    waybar
    kitty
    rofi-wayland
  ];

  home.stateVersion = "23.05";
}
