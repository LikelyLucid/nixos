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
    ../../modules/system/ydotool.nix
    ../../modules/work/work.nix
  ];

  ############################################
  # BITWARDEN SECRETS (self-hosted Vaultwarden)
  ############################################
  # bitwarden is disabled temporarily to simplify boot debugging
  bitwarden.enable = false;
  bitwarden.serverUrl = "https://vaultwarden.likelylucid.com";
  bitwarden.auth.method = "api-key";
  bitwarden.secrets = {
    tailscale-auth-key = {
      item = "Tailscale Auth Key";
      field = "password";
    };
  };

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
    
    # Better audio quality settings
    extraConfig.pipewire."92-high-quality" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 44100 48000 88200 96000 ];
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 2048;
      };
    };
  };

  ############################################
  # KERNEL
  ############################################
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  ############################################
  # PERFORMANCE TUNING
  ############################################
  zramSwap.enable = true;

  # SSD TRIM
  services.fstrim.enable = true;

  # Spread hardware IRQs across all CPU cores
  services.irqbalance.enable = true;

  boot.kernel.sysctl = {
    # Lower swappiness = keep things in RAM longer, good for SSDs
    "vm.swappiness" = 10;
    # Keep more filesystem metadata cached
    "vm.vfs_cache_pressure" = 50;
    # Write dirty pages to disk sooner — less RAM tied up, less stutter
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    # Increase TCP buffer maxes for better network throughput
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
  };

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
    chromium           # Chromium browser for OpenClaw browser control (CDP)
    easyeffects        # Audio effects/EQ (PipeWire compatible)
    tesseract          # OCR — read text from screenshots
    ydotool            # Wayland input injection (mouse/keyboard control)
    git
    gh
    htop
    lazygit
    pciutils
    pulsemixer         # Terminal audio mixer
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
