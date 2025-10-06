{ config, pkgs, ... }:
{
  ############################################
  # GRAPHICS & NVIDIA
  ############################################
  services.xserver.enable = false;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    prime = {
      offload.enable = true;
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

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --greeting 'Welcome back Arthur!' --cmd Hyprland";
      user = "greeter";
    };
  };

  ############################################
  # XDG PORTAL
  ############################################
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
  };

  ############################################
  # ENVIRONMENT VARIABLES
  ############################################
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSOR = "1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    ELECTRON_ENABLE_WAYLAND = "1";
    OZONE_PLATFORM = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    QT_QPA_PLATFORM = "wayland";
  };

  ############################################
  # SYSTEM PACKAGES
  ############################################
  environment.systemPackages = with pkgs; [
    alsa-utils
    brightnessctl
    bottom
    dunst
    flameshot
    grim
    grimblast
    hyprpolkitagent
    jq
    networkmanager_dmenu
    rofi-bluetooth
    slurp
    wl-clipboard
  ];
}
