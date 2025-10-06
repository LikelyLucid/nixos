{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fzf
    gemini-cli
    gnugrep
    neovim
    nodejs-slim_20
    ripgrep
    uv
    yazi
    zig
  ];

  home.sessionVariables.EDITOR = "nvim";
}
