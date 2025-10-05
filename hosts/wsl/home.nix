{ pkgs, lazyvim-config, dotfiles, ... }:
{
  imports = [
    ../../modules/dev/developer.nix
    ../../modules/notes/pandoc.nix
    ../../modules/dotfiles.nix
  ];

  home.username = "lucid";
  home.homeDirectory = "/home/lucid";

  ############################################
  # CLI-ONLY PACKAGES
  ############################################
  home.packages = with pkgs; [
    cava
    wallust
    spotify-player
    fastfetch
    codex
    python3
  ];

  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
  };

  home.stateVersion = "23.05";
}
