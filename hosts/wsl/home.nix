{ pkgs, lazyvim-config, dotfiles, ... }:
{
  imports = [
    ../modules/dev/developer.nix
    ../modules/dotfiles.nix
  ];

  home.username = "lucid";
  home.homeDirectory = "/home/lucid";

  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFile = ../secrets/secrets.yaml;
  };

  home.stateVersion = "23.05";
}
