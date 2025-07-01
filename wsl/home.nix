{ pkgs, lazyvim-config, ... }:
{
  imports = [
    ../modules/dev/developer.nix
  ];

  home.username = "lucid";
  home.homeDirectory = "/home/lucid";

  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFile = ../secrets/secrets.yaml;
  };

  home.stateVersion = "23.05";
}
