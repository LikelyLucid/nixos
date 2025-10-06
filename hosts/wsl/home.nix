{ ... }:
{
  ############################################
  # MODULE IMPORTS
  ############################################
  imports = [
    ../../modules/dev/developer.nix
    ../../modules/dotfiles.nix
  ];

  ############################################
  # USER DETAILS
  ############################################
  home.username = "lucid";
  home.homeDirectory = "/home/lucid";

  ############################################
  # SOPS
  ############################################
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
  };

  ############################################
  # STATE VERSION
  ############################################
  home.stateVersion = "23.05";
}
