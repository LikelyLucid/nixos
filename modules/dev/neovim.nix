{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fzf
    gnugrep
    neovim
    yazi
    zig
  ];

  home.sessionVariables.EDITOR = "nvim";
}
