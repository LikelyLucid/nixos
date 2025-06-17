# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      # <nixos-hardware/dell/xps/15-9530>
      ./hardware-configuration.nix
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

  # -------------------------------------------------
  # NVIDIA + Wayland / Hyprland
  # -------------------------------------------------
  services.xserver.enable = false;         # pure Wayland session
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;      # required for Wayland
    powerManagement.enable = true;
    open = false;                   # set to true if GPU supports the open driver
    prime = {
      offload.enable = true;        # hybrid graphics off-load
      intelBusId  = "PCI:0:2:0";   # Intel iGPU (00:02.0)
      nvidiaBusId = "PCI:1:0:0";   # NVIDIA dGPU (01:00.0)
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;         # XWayland for legacy apps
    nvidiaPatches = true;           # extra patches for NVIDIA/Wayland
  };

  # ---------------------------------------------
  # Display / Login manager (greetd + tuigreet)
  # ---------------------------------------------
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # XDG portals (screencast, file‑open dialogs, etc.)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
  };

  # Libinput for touchpad / mouse
  # services.libinput.enable = true;

  # -------------------------------------------------
  # Audio (PipeWire on Wayland)
  # -------------------------------------------------
  services.pulseaudio.enable = false;
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

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSOR = "1";              # avoids cursor corruption on NVIDIA
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  environment.systemPackages = with pkgs; [
    neovim wget git pciutils htop gh lazygit
  ];

  # -------------------------------------------------
  # System version (do not change lightly)
  # -------------------------------------------------
  system.stateVersion = "25.05";
}

