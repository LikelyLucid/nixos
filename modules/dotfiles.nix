{ config, dotfiles, ... }:
let
  mk_link = config.lib.file.mkOutOfStoreSymlink;
  config_links = {
    "hypr/hyprland.conf" = "hypr/hyprland.conf";
    "kitty" = "kitty";
    "rofi" = "rofi";
    "waybar" = "waybar";
    "spotify-player" = "spotify-player";
    "wallust" = "wallust";
    "flameshot" = "flameshot";
    "nvim" = "nvim";
  };
in {
  xdg.configFile =
    builtins.mapAttrs
      (_: relative_path: {
        source = mk_link "${dotfiles}/${relative_path}";
      })
      config_links;
}
