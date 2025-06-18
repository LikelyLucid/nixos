{ pkgs, ... }:
{
  imports = [
    ./neovim.nix
    ./tmux.nix
  ];
}
