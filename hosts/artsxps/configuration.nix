{ config, lib, pkgs, ... }:
{
  ############################################
  # IMPORTS
  ############################################
  imports = [
    ./hardware-configuration.nix
    ../../modules/window-manager/window-manager.nix
    ../../modules/networking/tailscale.nix
    ../../modules/system/locale.nix
  ];

  ############################################
  # NIX SETTINGS
  ############################################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  ############################################
  # BOOTLOADER
  ############################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.default = 0;

  ############################################
  # BOOT SPLASH
  ############################################
  boot.plymouth = {
    enable = true;
    theme = "dark_planet";
    themePackages = with pkgs; [ adi1090x-plymouth-themes ];
  };

  ############################################
  # HOSTNAME & NETWORKING
  ############################################
  networking.hostName = "artsxps";
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  ############################################
  # POWER MANAGEMENT
  ############################################
  services.thermald.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 20;
    };
  };

  ############################################
  # AUDIO
  ############################################
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  ############################################
  # KERNEL
  ############################################
  boot.kernelPackages = pkgs.linuxPackages_latest;

  ############################################
  # USERS
  ############################################
  users.users.lucid = {
    isNormalUser = true;
    description = "Arthur Mckellar";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  ############################################
  # PACKAGES & PROGRAMS
  ############################################
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    age
    git
    gh
    htop
    lazygit
    pciutils
    sops
    syncthing
    texlive.combined.scheme-full
    wget
    zip
  ];

  ############################################
  # COMPATIBILITY UTILITIES
  ############################################
  systemd.tmpfiles.rules = [
    "L /usr/bin/which - - - - ${pkgs.which}/bin/which"
  ];
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 5d --keep 5";
    flake = "/home/lucid/nixos";
  };

  ############################################
  # FONTS
  ############################################
  fonts.packages = with pkgs; [
    jetbrains-mono
    pkgs.nerd-fonts.jetbrains-mono
  ];

  ############################################
  # STATE VERSION
  ############################################
  system.stateVersion = "25.05";
}
