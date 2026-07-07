{
  config,
  lib,
  pkgs,
  ...
}:
let
  tuigreet = lib.getExe pkgs.tuigreet;
  hyprland_session = "start-hyprland";
in
{
  ############################################
  # GRAPHICS & NVIDIA
  ############################################
  services.xserver.enable = false;
  services.xserver.videoDrivers = [
    "nvidia"
    "displaylink"
  ];
  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    open = false;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  ############################################
  # HYPRLAND
  ############################################
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  programs.hyprlock.enable = true;
  services.hypridle.enable = true;
  services.gnome.at-spi2-core.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${tuigreet} --time --greeting 'Welcome back Arthur!' --cmd ${hyprland_session}";
      user = "greeter";
    };
  };

  ############################################
  # XDG PORTAL
  ############################################
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
    config.common.default = [
      "hyprland"
      "gtk"
    ];
  };

  ############################################
  # ENVIRONMENT VARIABLES
  ############################################
  environment.sessionVariables = {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    ELECTRON_ENABLE_WAYLAND = "1";
    OZONE_PLATFORM = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    QT_QPA_PLATFORM = "wayland";
    CUA_DRIVER_RS_ENABLE_WAYLAND = "1";
  };

  ############################################
  # SYSTEM PACKAGES
  ############################################
  environment.systemPackages = with pkgs; [
    alsa-utils
    brightnessctl
    blueman # Bluetooth manager GUI
    bottom
    cliphist # Clipboard manager with history
    dunst
    flameshot
    ghostty # Fast terminal emulator
    grim
    grimblast
    hyprpolkitagent
    jq
    networkmanagerapplet # Network tray applet + connection editor
    networkmanager_dmenu
    nwg-displays # Monitor config GUI
    pavucontrol # Audio mixer
    playerctl # Media player controls
    rofi-bluetooth
    slurp
    swappy # Screenshot annotation
    wl-clipboard
    wlr-randr # Monitor config CLI
  ];
}
