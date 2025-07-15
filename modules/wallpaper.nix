{ config, pkgs, lib, ... }:

let
  wallpaper = config.wallpaper;
in
{
  # allow users to set the wallpaper
  config.wallpaper = lib.mkOption {
    type = lib.types.str;
    default = "/etc/wallpaper.png";
    description = "The wallpaper to use for the system.";
  };

  # set the wallpaper
  environment.etc."wallpaper.png".source = wallpaper;

  # set the theme
  wallust.enable = true;
  wallust.settings = {
    inherit wallpaper;
  };
}
