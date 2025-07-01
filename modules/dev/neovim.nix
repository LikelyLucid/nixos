{ pkgs, lazyvim-config, lib, ... }:
{
  home.packages = with pkgs; [ neovim zig ripgrep gnugrep fzf uv nodejs-slim_20 yazi];
  home.activation.copyNvimConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
  rm -rf ~/.config/nvim
  cp -r ${lazyvim-config} ~/.config/nvim
  chmod -R u+w ~/.config/nvim
  '';

  home.sessionVariables = {
    EDITOR = "nvim";
  };

}
