{ lib, dotfiles, ... }:
{
  xdg.configFile."hypr".source = lib.file.mkOutOfStoreSymlink "${dotfiles}/hypr";
  xdg.configFile."kitty".source = lib.file.mkOutOfStoreSymlink "${dotfiles}/kitty";
  xdg.configFile."rofi".source = lib.file.mkOutOfStoreSymlink "${dotfiles}/rofi";
  xdg.configFile."waybar".source = lib.file.mkOutOfStoreSymlink "${dotfiles}/waybar";
  xdg.configFile."spotify-player".source = lib.file.mkOutOfStoreSymlink "${dotfiles}/spotify-player";
  xdg.configFile."wallust".source = lib.file.mkOutOfStoreSymlink "${dotfiles}/wallust";
  xdg.configFile."flameshot".source = lib.file.mkOutOfStoreSymlink "${dotfiles}/flameshot";
  xdg.configFile."nvim".source = lib.file.mkOutOfStoreSymlink "${dotfiles}/nvim";
}

