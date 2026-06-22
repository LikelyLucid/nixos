{ pkgs, dotfiles, ... }:
let
  wallpaper_path = "${dotfiles}/media/wallpapers/Wallpaper 4.jpg";
  hyprland_config = builtins.replaceStrings [
    "    pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below\n"
    "bind = $mainMod, J, togglesplit, # dwindle"
    "windowrule = suppressevent maximize, class:.*"
    "windowrule = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
  ] [
    ""
    "bind = $mainMod, J, layoutmsg, togglesplit # dwindle"
    "windowrule = match:class .*, suppress_event maximize"
    "windowrule = match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false, no_focus true"
  ] (builtins.readFile "${dotfiles}/hypr/hyprland.conf");
in {
  ############################################
  # HYPRPAPER
  ############################################
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      preload = wallpaper_path;
      wallpaper = ",${wallpaper_path}";
    };
  };

  ############################################
  # HYPRLAND SESSION HELPERS
  ############################################
  xdg.configFile."hypr/hyprland.conf".text = hyprland_config + ''
    source = ~/.config/hypr/monitors.conf

    $terminal = ghostty
    $fileManager = nemo
    bind = $mainMod, E, exec, $fileManager
    
    exec-once = hyprpaper &
    exec-once = nm-applet &
    exec-once = blueman-applet &
    exec-once = dunst &
    exec-once = wl-paste --watch cliphist store
    
    # Clipboard history
    bind = SUPER, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
    bind = SUPER SHIFT, V, exec, cliphist list | rofi -dmenu -p "Clipboard" | cliphist decode | wl-copy
    
    # Screenshot tools
    # Rofi launcher: Ctrl+Tab cycles modes (drun, run, window, system)
    bind = $mainMod, R, exec, rofi -show drun -modi "drun,run,window,system:~/.config/hypr/scripts/rofi-system.sh"
    
    bind = , Print, exec, grim -g "$(slurp)" - | swappy -f -
    bind = SHIFT, Print, exec, grim - | swappy -f -
  '';

  # Rofi system mode script (switched via Ctrl+Tab inside rofi)
  home.file.".config/hypr/scripts/rofi-system.sh" = {
    text = ''
      #!/usr/bin/env bash
      if [ -n "$1" ]; then
        case "$1" in
          *Bluetooth*) blueman-manager ;;
          *WiFi*) nm-connection-editor ;;
          *Audio*) pavucontrol ;;
          *Monitors*) nwg-displays ;;
          *Screenshot*(area)*) grim -g "$(slurp)" - | swappy -f - ;;
          *Screenshot*(full)*) grim - | swappy -f - ;;
          *Lock*) hyprlock ;;
          *Clipboard*) cliphist list | rofi -dmenu -p Clipboard | cliphist decode | wl-copy ;;
          *Disturb*) dunstctl set-paused toggle ;;
          *Sleep*) systemctl suspend ;;
          *Reboot*) systemctl reboot ;;
          *Shutdown*) systemctl poweroff ;;
          *Logout*) hyprctl dispatch exit ;;
        esac
      else
        printf '%s\n' \
          "Bluetooth" \
          "WiFi" \
          "Audio" \
          "Monitors" \
          "Screenshot (area)" \
          "Screenshot (full)" \
          "Lock Screen" \
          "Clipboard" \
          "Do Not Disturb" \
          "Sleep" \
          "Reboot" \
          "Shutdown" \
          "Logout"
      fi
    '';
    executable = true;
  };

  services.playerctld.enable = true;
  
  # Ghostty terminal config (wallust will add colors)
  programs.ghostty.enable = true;
  programs.hyprlock.enable = true;

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "hyprlock";
        before_sleep_cmd = "hyprlock";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "hyprlock";
        }
        {
          timeout = 600;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
