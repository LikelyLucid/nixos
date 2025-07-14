{ config, pkgs, ... }:
{
  ############################################
  # SHARED CONFIGURATION
  ############################################
  imports = [
    ../../modules/shared/base.nix
  ];

  ############################################
  # WSL-SPECIFIC CONFIGURATION
  ############################################
  wsl.enable = true;
  wsl.defaultUser = "lucid";

  ############################################
  # HOSTNAME & NETWORKING
  ############################################
  networking.hostName = "nixos-wsl";
  networking.networkmanager.enable = true;

  # sops = {
  #   age.keyFile = "/var/lib/sops-nix/key.txt";
  #   defaultSopsFile = ../../secrets/secrets.yaml;
  #
  # };
}
