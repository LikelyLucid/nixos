{ ... }:
{
  nixos.modules.desktop =
    {
      lib,
      pkgs,
      ...
    }:
    let
      tuigreet = lib.getExe pkgs.tuigreet;
      hyprland_session = "uwsm start -S -F /run/current-system/sw/bin/Hyprland";
    in
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
        kdePackages.spectacle # GUI screenshots, annotation, and screen recording
        hyprpolkitagent
        jq
        networkmanagerapplet # Network tray applet + connection editor
        networkmanager_dmenu
        nwg-displays # Monitor config GUI
        pavucontrol # Audio mixer
        playerctl # Media player controls
        rofi-bluetooth
        wl-clipboard
        wlr-randr # Monitor config CLI
      ];
    };
}
