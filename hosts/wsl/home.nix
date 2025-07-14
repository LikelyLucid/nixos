{ pkgs, lazyvim-config, dotfiles, ... }:
{
  ############################################
  # SHARED HOME CONFIGURATION
  ############################################
  imports = [
    ../modules/shared/base-home.nix
  ];

  ############################################
  # WSL-SPECIFIC SOPS CONFIGURATION
  ############################################
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFile = ../secrets/secrets.yaml;
  };
}
