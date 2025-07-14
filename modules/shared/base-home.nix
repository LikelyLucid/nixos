{ pkgs, ... }:

{
  ############################################
  # HOME CONFIGURATION
  ############################################
  home.username = "lucid";
  home.homeDirectory = "/home/lucid";

  ############################################
  # SHARED IMPORTS
  ############################################
  imports = [
    ../dev/developer.nix
    ../dotfiles.nix
  ];

  ############################################
  # HOME STATE VERSION
  ############################################
  home.stateVersion = "23.05";
}