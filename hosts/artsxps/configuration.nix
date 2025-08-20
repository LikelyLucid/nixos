############################################
# DELL XPS 15 9530 NIXOS CONFIGURATION
############################################
# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  ############################################
  # IMPORTS
  ############################################
  imports = [
    # Hardware configuration
    ./hardware-configuration.nix
    # System modules
    ../../modules/window-manager/window-manager.nix
    ../../modules/networking/tailscale.nix
    ../../modules/security/security.nix
    ../../modules/system/monitoring.nix
    ../../modules/system/performance.nix
  ];

  nix.settings = {
    # You can leave the package line out if you’re happy with the Nix that ships
    # with your current channel; keeping it explicit avoids surprises.
    # package = pkgs.nix;

    experimental-features = [ "nix-command" "flakes" ];
    
    # Optimize store and enable auto-optimise  
    auto-optimise-store = true;
    
    # Trusted users for nix operations
    trusted-users = [ "root" "lucid" ];
  };

  ############################################
  # BOOTLOADER CONFIGURATION  
  ############################################
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ############################################
  # HOSTNAME & NETWORKING
  ############################################
  networking.hostName = "artsxps";
  networking.networkmanager.enable = true;
  # networking.networkmanager.tailscale.ssids = [ "UCWireless" "UCVisitor" ];

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  ############################################
  # HARDWARE CONFIGURATION
  ############################################
  
  # Thermal management
  services.thermald.enable = true;

  # Power management with TLP
  services.tlp = {
    enable = true;
    settings = {
      # CPU scaling
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      # CPU energy performance policy  
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

      # CPU performance limits
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 20;

      # Battery charge thresholds (uncomment for battery health)
      # START_CHARGE_THRESH_BAT0 = 40; # Start charging at 40%
      # STOP_CHARGE_THRESH_BAT0 = 80;  # Stop charging at 80%
    };
  };

  # Use latest kernel packages
  boot.kernelPackages = pkgs.linuxPackages_latest;
  ############################################
  # LOCALE & TIMEZONE
  ############################################
  # LOCALE & TIMEZONE
  ############################################
  time.timeZone = "Pacific/Auckland";
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS      = "en_NZ.UTF-8";
    LC_IDENTIFICATION = "en_NZ.UTF-8";
    LC_MEASUREMENT  = "en_NZ.UTF-8";
    LC_MONETARY     = "en_NZ.UTF-8";
    LC_NAME         = "en_NZ.UTF-8";
    LC_NUMERIC      = "en_NZ.UTF-8";
    LC_PAPER        = "en_NZ.UTF-8";
    LC_TELEPHONE    = "en_NZ.UTF-8";
    LC_TIME         = "en_NZ.UTF-8";
  };

  ############################################
  # AUDIO CONFIGURATION
  ############################################
  # Enable real-time kit for audio
  security.rtkit.enable = true;
  
  # PipeWire audio server  
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  ############################################
  # USER CONFIGURATION
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
  # SYSTEM PACKAGES & ENVIRONMENT
  ############################################
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Essential system packages
  environment.systemPackages = with pkgs; [
    # System utilities
    wget
    git
    pciutils
    htop
    
    # Development tools
    gh
    lazygit
    
    # Security tools
    sops
    age
    
    # File sync
    syncthing
    
    # Document processing
    texlive.combined.scheme-full
  ];

  # Nix Helper for easier system management
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 5d --keep 5";
    flake = "/home/lucid/nixos";
  };

  # System fonts
  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.jetbrains-mono
  ];
  ############################################
  # SYSTEM VERSION
  ############################################
  # Do not change lightly - this sets the NixOS release version
  system.stateVersion = "25.05";
}

