{ config, lib, dotfiles, ... }:
{
  xdg.configFile."hypr".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr";
  xdg.configFile."kitty".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/kitty";
  xdg.configFile."rofi".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/rofi";
  xdg.configFile."waybar".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/waybar";
  xdg.configFile."spotify-player".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/spotify-player";
  xdg.configFile."wallust".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/wallust";
  xdg.configFile."flameshot".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/flameshot";
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
}

