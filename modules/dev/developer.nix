{ pkgs, ... }:
{
  ############################################
  # TOOLING IMPORTS
  ############################################
  imports = [
    ./neovim.nix
    ./tmux.nix
    ./zsh.nix
  ];

  ############################################
  # GIT CONFIG
  ############################################
  programs.git = {
    enable = true;
    settings = {
      user.name = "LikelyLucid";
      user.email = "micoolplays@gmail.com";
      core.editor = "nvim";
      pull.rebase = true;
    };
  };
}
