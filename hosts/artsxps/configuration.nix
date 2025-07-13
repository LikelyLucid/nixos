# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      # <nixos-hardware/dell/xps/15-9530>
      ./hardware-configuration.nix
      ../../modules/window-manager/window-manager.nix
      # ./modules/audio/dell_xps_speakers.nix
    ];

  nix.settings = {
    # You can leave the package line out if you’re happy with the Nix that ships
    # with your current channel; keeping it explicit avoids surprises.
    # package = pkgs.nix;

    experimental-features = [ "nix-command" "flakes" ];
  };

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

  boot.kernelPackages = pkgs.linuxPackages_latest;
  # hardware.enableAllFirmware = true;

  # -------------------------------------------------
  # Users
  # -------------------------------------------------
  users.users.lucid = {
    isNormalUser = true;
    description = "Arthur Mckellar";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.zsh;
  };
  users.defaultUserShell = pkgs.zsh;

  programs.zsh.enable = true;

  # -------------------------------------------------
  # Environment / Packages & Vars
  # -------------------------------------------------
  nixpkgs.config.allowUnfree = true;


  environment.systemPackages = with pkgs; [
    wget git pciutils htop gh lazygit sops age syncthing
  ];

  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 5d --keep 5";
    flake = "/etc/nixos";
  };

 fonts.packages = with pkgs; [
    jetbrains-mono
    pkgs.nerd-fonts.jetbrains-mono
    # (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
  # -------------------------------------------------
  # System version (do not change lightly)
  # -------------------------------------------------
  system.stateVersion = "25.05";
}

