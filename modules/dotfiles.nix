{ ... }:
{
  homeManager.modules.common =
    {
      config,
      lib,
      osConfig,
      ...
    }:
    let
      isWsl = osConfig.wsl.enable or false;
      mk_link = config.lib.file.mkOutOfStoreSymlink;
      dotfiles_dir = "/home/lucid/dotfiles";

      # Desktop-only symlinks (from dotfiles flake input)
      desktop_links = lib.optionalAttrs (!isWsl) {
        "rofi" = "rofi";
        "waybar" = "waybar";
        "eww" = "eww";
        "wallust" = "wallust";
        # Hokum rewrites its config when DND or the theme changes, so it needs a
        # writable out-of-store path like the wallust-generated files above.
        "hokum" = "hokum";
      };

      all_links = desktop_links;
    in
    {
      xdg.configFile = builtins.mapAttrs (_: relative_path: {
        source = mk_link "${dotfiles_dir}/${relative_path}";
      }) all_links;
    };
}
