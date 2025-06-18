# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      # <nixos-hardware/dell/xps/15-9530>
      ./hardware-configuration.nix
      ./modules/window-manager/window-manager.nix
    ];


  # -------------------------------------------------
  # Bootloader
  # -------------------------------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # -------------------------------------------------
  # Hostname & Networking
  # -------------------------------------------------
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # -------------------------------------------------
  # Locale / Timezone
  # -------------------------------------------------
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

  # Libinput for touchpad / mouse
  # services.libinput.enable = true;

  # -------------------------------------------------
  # Audio (PipeWire on Wayland)
  # -------------------------------------------------
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # -------------------------------------------------
  # Users
  # -------------------------------------------------
  users.users.lucid = {
    isNormalUser = true;
    description = "Arthur Mckellar";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # -------------------------------------------------
  # Environment / Packages & Vars
  # -------------------------------------------------
  nixpkgs.config.allowUnfree = true;


  environment.systemPackages = with pkgs; [
    neovim wget git pciutils htop gh lazygit
  ];

  fonts.packages = with pkgs; [
    jetbrains-mono
  ];

  # -------------------------------------------------
  # System version (do not change lightly)
  # -------------------------------------------------
  system.stateVersion = "25.05";
}

