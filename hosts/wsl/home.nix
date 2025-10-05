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
    python3
    fastfetch
  ];

  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
  };

  home.stateVersion = "23.05";
}
