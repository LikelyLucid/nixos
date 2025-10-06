{ pkgs, ... }:
{
  ############################################
  # IMPORTS
  ############################################
  imports = [
    ../../modules/system/locale.nix
  ];

  ############################################
  # WSL
  ############################################
  wsl.enable = true;
  wsl.defaultUser = "lucid";
  wsl.wslConf.boot.systemd = true;

  ############################################
  # NIX SETTINGS
  ############################################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  ############################################
  # HOSTNAME & NETWORKING
  ############################################
  networking.hostName = "nixos-wsl";

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
    age
    git
    gh
    htop
    lazygit
    sops
    wget
  ];

  ############################################
  # STATE VERSION
  ############################################
  system.stateVersion = "25.05";
}
