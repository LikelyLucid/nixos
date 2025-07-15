{ config, pkgs, ... }:
{
  services.xserver.enable = false;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

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

  # autologin
  services.getty.autologinUser = "lucid";
  services.greetd.enable = false;

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
      };
      background = {
        path = "/home/lucid/Pictures/Wallpapers/nix-wallpaper.png";
        blur_passes = 3;
        contrast = 0.8916;
        brightness = 0.8172;
        vibrancy = 0.1696;
        vibrancy_darkness = 0.0;
      };
      "input-field" = {
        size = "200, 50";
        outline_thickness = 3;
        dots_size = 0.33;
        dots_spacing = 0.15;
        dots_center = true;
        dots_rounding = -1;
        outer_color = "rgb(15, 15, 15)";
        inner_color = "rgb(200, 200, 200)";
        font_color = "rgb(10, 10, 10)";
        fade_on_empty = true;
        placeholder_text = "<i>Password...</i>";
        hide_input = false;
        rounding = -1;
        check_color = "rgb(204, 136, 34)";
        fail_color = "rgb(204, 34, 34)";
        fail_text = "<i>$FAIL</i>";
        fail_transition = 300;
        capslock_color = -1;
        numlock_color = -1;
        bothlock_color = -1;
        invert_numlock = false;
        swap_font_color = false;
      };
      label = [
        {
          text = "Hi there, $USER";
          color = "rgba(255, 255, 255, 0.6)";
          font_size = 20;
          font_family = "JetBrains Mono Nerd Font";
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
        {
          text = "$TIME";
          color = "rgba(255, 255, 255, 0.6)";
          font_size = 60;
          font_family = "JetBrains Mono Nerd Font";
          position = "0, -100";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 150;
          on-timeout = "brightnessctl -s set 10%";
          on-resume = "brightnessctl -r";
        }
        {
          timeout = 300;
          on-timeout = "hyprlock";
        }
        {
          timeout = 330;
          on-timeout = "systemctl suspend";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
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

