{ config, pkgs, ... }:
{
  services.xserver.enable = false;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    prime = {
      offload.enable = true;
      intelBusId  = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # nvidiaPatches = true; # Not needed now, yahoo
  };

  programs.hyprlock.enable = true;
  services.hypridle.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --greeting 'Welcome back Arthur!' --cmd Hyprland";
	user = "greeter";
      };
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
  };

  environment.sessionVariables = {
    # existing ones
    WLR_NO_HARDWARE_CURSOR    = "1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    # Electron/Wayland/Ozone for Obsidian & friends:
    ELECTRON_ENABLE_WAYLAND   = "1";
    OZONE_PLATFORM            = "wayland";
    XDG_CURRENT_DESKTOP       = "Hyprland";
    XDG_SESSION_TYPE          = "wayland";
    XDG_SESSION_DESKTOP       = "Hyprland";
    QT_QPA_PLATFORM           = "wayland";
  };

  environment.systemPackages = with pkgs; [
    jq brightnessctl rofi-bluetooth networkmanager_dmenu
    alsa-utils dunst hyprpolkitagent wl-clipboard bottom flameshot slurp grim grimblast
  ];
}

