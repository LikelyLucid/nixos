{ pkgs, ... }: {
  programs.zsh = {
    enable = true;
    ohMyZsh.enable = true;
  };
  programs.starship.enable = true;
}
