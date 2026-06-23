{
  config,
  lib,
  dotfiles,
  isWsl ? false,
  ...
}:
let
  mk_link = config.lib.file.mkOutOfStoreSymlink;
  dotfiles_dir = "/home/lucid/dotfiles";

  # Desktop-only symlinks (from dotfiles flake input)
  desktop_links = lib.optionalAttrs (!isWsl) {
    "rofi" = "rofi";
    "waybar" = "waybar";
    "wallust" = "wallust";
    "flameshot" = "flameshot";
  };

  # Common symlinks (from dotfiles flake input)
  common_links = {
    # nvim is managed locally so edits are picked up immediately
  };

  all_links = common_links // desktop_links;
in
{
  xdg.configFile =
    builtins.mapAttrs (_: relative_path: {
      source = mk_link "${dotfiles_dir}/${relative_path}";
    }) all_links
    # dotfiles use local paths so wallust-generated files update live
    // {
      nvim.source = mk_link "/home/lucid/dotfiles/nvim";
    };
}
