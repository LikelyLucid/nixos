{ config, lib, dotfiles, isWsl ? false, ... }:
let
  mk_link = config.lib.file.mkOutOfStoreSymlink;

  # Symlinks that work on both WSL and desktop Linux
  common_links = {
    "nvim" = "nvim";
  };

  # Symlinks that only make sense on desktop Linux (with display server)
  desktop_links = lib.optionalAttrs (!isWsl) {
    "hypr/hyprland.conf" = "hypr/hyprland.conf";
    "kitty" = "kitty";
    "rofi" = "rofi";
    "waybar" = "waybar";
    "spotify-player" = "spotify-player";
    "wallust" = "wallust";
    "flameshot" = "flameshot";
  };

  all_links = common_links // desktop_links;
in {
  xdg.configFile =
    builtins.mapAttrs
      (_: relative_path: {
        source = mk_link "${dotfiles}/${relative_path}";
      })
      all_links;
}
