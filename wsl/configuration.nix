{ config, pkgs, ... }:
{
  wsl.enable = true;
  wsl.defaultUser = "lucid";

  ############################################
  # NIX SETTINGS
  ############################################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  ############################################
  # HOSTNAME & NETWORKING
  ############################################
  networking.hostName = "nixos-wsl";
  networking.networkmanager.enable = true;

  ############################################
  # LOCALE / TIMEZONE
  ############################################
  time.timeZone = "Pacific/Auckland";
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_NZ.UTF-8";
    LC_IDENTIFICATION = "en_NZ.UTF-8";
    LC_MEASUREMENT = "en_NZ.UTF-8";
    LC_MONETARY = "en_NZ.UTF-8";
    LC_NAME = "en_NZ.UTF-8";
    LC_NUMERIC = "en_NZ.UTF-8";
    LC_PAPER = "en_NZ.UTF-8";
    LC_TELEPHONE = "en_NZ.UTF-8";
    LC_TIME = "en_NZ.UTF-8";
  };

  ############################################
  # USERS
  ############################################
  users.users.lucid = {
    isNormalUser = true;
    description = "Arthur Mckellar";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };
  users.defaultUserShell = pkgs.zsh;

  programs.zsh.enable = true;

  ############################################
  # PACKAGES
  ############################################
  environment.systemPackages = with pkgs; [
    wget git htop gh lazygit sops age
  ];

  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    age.generateKey = true;
    defaultSopsFile = ../secrets/secrets.yaml;
  };

  ############################################
  # SYSTEM VERSION
  ############################################
  system.stateVersion = "25.05";
}
