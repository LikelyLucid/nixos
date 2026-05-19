{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fzf
    gnugrep
    neovim
    ripgrep
    uv
    yazi
    zig
  ];

  home.sessionVariables.EDITOR = "nvim";
}
