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
    userName = "LikelyLucid";
    userEmail = "micoolplays@gmail.com";
    extraConfig = {
      core.editor = "nvim";
      pull.rebase = true;
    };
  };
}
