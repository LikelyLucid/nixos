{ ... }:
{
  nixos.modules.desktop =
    { pkgs, ... }:
    {
      ############################################
      # GRAPHICS
      ############################################
      services.xserver.enable = false;
      services.xserver.videoDrivers = [ "displaylink" ];
      hardware.graphics.enable = true;

      ############################################
      # HYPRLAND
      ############################################
      programs.hyprland = {
        enable = true;
        withUWSM = true;
        xwayland.enable = true;
      };
      programs.hyprlock.enable = true;
      services.hypridle.enable = true;
      services.gnome.at-spi2-core.enable = true;

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
        fuse3 # Required by xdg-document-portal for native file pickers
        ghostty # Fast terminal emulator
        grim # Native Wayland screenshots
        hyprpolkitagent
        jq
        networkmanagerapplet # Network tray applet + connection editor
        networkmanager_dmenu
        nwg-displays # Monitor config GUI
        pavucontrol # Audio mixer
        playerctl # Media player controls
        rofi-bluetooth
        slurp # Interactive screenshot region selection
        swappy # Screenshot annotation
        wl-clipboard
        wlr-randr # Monitor config CLI
      ];
    };
}
