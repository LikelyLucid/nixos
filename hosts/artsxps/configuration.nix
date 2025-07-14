# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      # <nixos-hardware/dell/xps/15-9530>
      ./hardware-configuration.nix
      ../../modules/shared/base.nix
      ../../modules/window-manager/window-manager.nix
      # ./modules/audio/dell_xps_speakers.nix
      ../../modules/networking/tailscale.nix
    ];

  # -------------------------------------------------
  # Bootloader
  # -------------------------------------------------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # -------------------------------------------------
  # Hostname & Networking
  # -------------------------------------------------
  networking.hostName = "artsxps";
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # -------------------------------------------------
  # Battery
  # -------------------------------------------------

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

       #Optional helps save long term battery health
       # START_CHARGE_THRESH_BAT0 = 40; # 40 and below it starts to charge
       # STOP_CHARGE_THRESH_BAT0 = 80; # 80 and above it stops charging

      };
  };
  # -------------------------------------------------
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

  boot.kernelPackages = pkgs.linuxPackages_latest;
  # hardware.enableAllFirmware = true;

  # -------------------------------------------------
  # Additional User Groups (hardware-specific)
  # -------------------------------------------------
  users.users.lucid.extraGroups = [ "networkmanager" ];

  # -------------------------------------------------
  # Environment / Packages & Vars
  # -------------------------------------------------
  nixpkgs.config.allowUnfree = true;


  environment.systemPackages = with pkgs; [
    # Hardware-specific packages
    pciutils
    syncthing
  ];

  

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 5d --keep 5";
    flake = "~/nixos";
  };

 fonts.packages = with pkgs; [
    jetbrains-mono
    pkgs.nerd-fonts.jetbrains-mono
    # (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
}

