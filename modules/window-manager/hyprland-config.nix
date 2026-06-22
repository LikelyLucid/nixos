{
  config,
  pkgs,
  dotfiles,
  ...
}:
let
  wallpaper_path = "${dotfiles}/media/wallpapers/wallpaper.jpg";
  hyprland_config =
    builtins.replaceStrings
      [
        "$fileManager = $terminal -- yazi"
        "    pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below\n"
        "bind = $mainMod, J, togglesplit, # dwindle"
        "# Lockscreen\nbind = $mainMod, L, exec, hyprlock\n"
        "windowrule = suppressevent maximize, class:.*"
        "windowrule = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
      ]
      [
        "$fileManager = nemo"
        ""
        "bind = $mainMod, T, layoutmsg, togglesplit # dwindle"
        ""
        "windowrule = match:class .*, suppress_event maximize"
        "windowrule = match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false, no_focus true"
      ]
      (builtins.readFile "${dotfiles}/hypr/hyprland.conf");
in
{
  ############################################
  # HYPRPAPER
  ############################################
  services.hyprpaper.enable = true;

  # Generate hyprpaper.conf directly (v0.8.4 uses block syntax)
  xdg.configFile."hypr/hyprpaper.conf" = {
    text = ''
      ipc=on
      splash=false
      preload=${wallpaper_path}
      wallpaper {
        monitor=
        path=${wallpaper_path}
        fit_mode=cover
      }
    '';
  };

  ############################################
  # HYPRLAND SESSION HELPERS
  ############################################
  xdg.configFile."hypr/hyprland.conf".text = hyprland_config + ''
    source = ~/.config/hypr/monitors.conf

    $terminal = ghostty
    $fileManager = nemo

    exec-once = hyprpaper
    exec-once = nm-applet &
    exec-once = blueman-applet &
    exec-once = swaync &
    exec-once = wl-paste --watch cliphist store

    # Clipboard history
    bind = SUPER, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
    bind = SUPER SHIFT, V, exec, cliphist list | rofi -dmenu -p "Clipboard" | cliphist decode | wl-copy

    # Screenshot tools
    # Rofi launcher: Ctrl+Tab cycles modes (drun, run, window, system)
    bind = $mainMod, R, exec, rofi -show drun -modi "drun,run,window,system:${config.home.homeDirectory}/.config/hypr/scripts/rofi-system.sh"

    bind = , Print, exec, grim -g "$(slurp)" - | swappy -f -
    bind = SHIFT, Print, exec, grim - | swappy -f -

    # === CORNE-FRIENDLY KEYBINDS (40%, no number row) ===
    # Home-row window focus (semicolon keeps Super+L free for lock)
    bind = $mainMod, h, movefocus, l
    bind = $mainMod, j, movefocus, d
    bind = $mainMod, k, movefocus, u
    bind = $mainMod, semicolon, movefocus, r

    # comma/period for workspace cycling (base-layer keys on Corne)
    bind = $mainMod, comma, workspace, e-1
    bind = $mainMod, period, workspace, e+1
    bind = $mainMod SHIFT, comma, movetoworkspace, e-1
    bind = $mainMod SHIFT, period, movetoworkspace, e+1

    # Move window within workspace (swap direction)
    bind = $mainMod SHIFT, h, movewindow, l
    bind = $mainMod SHIFT, j, movewindow, d
    bind = $mainMod SHIFT, k, movewindow, u
    bind = $mainMod SHIFT, semicolon, movewindow, r

    # Resize mode (B for Bigger/Smaller)
    bind = $mainMod, B, submap, resize
    submap = resize
    bind = , h, resizeactive, -40 0
    bind = , j, resizeactive, 0 40
    bind = , k, resizeactive, 0 -40
    bind = , l, resizeactive, 40 0
    bind = , escape, submap, reset
    bind = , Return, submap, reset
    submap = reset

    # Cheatsheet: SUPER + / shows all binds
    bind = $mainMod, slash, exec, ~/.config/hypr/scripts/cheatsheet.sh
  '';

  # Rofi system mode script (switched via Ctrl+Tab inside rofi)
  home.file = {
    ".config/hypr/scripts/rofi-system.sh" = {
      text = ''
        #!/usr/bin/env bash
        if [ -n "$1" ]; then
          case "$1" in
            "Bluetooth Settings") blueman-manager ;;
            "Bluetooth Quick Connect") rofi-bluetooth ;;
            "Network Settings") nm-connection-editor ;;
            "WiFi Quick Connect") networkmanager_dmenu ;;
            "Audio") pavucontrol ;;
            "Monitors") nwg-displays ;;
            "Screenshot (area)") grim -g "$(slurp)" - | swappy -f - ;;
            "Screenshot (full)") grim - | swappy -f - ;;
            "Lock Screen") hyprlock ;;
            "Clipboard") cliphist list | rofi -dmenu -p Clipboard | cliphist decode | wl-copy ;;
            "Do Not Disturb") swaync-client -d ;;
            "Sleep") systemctl suspend ;;
            "Reboot") systemctl reboot ;;
            "Shutdown") systemctl poweroff ;;
            "Logout") hyprctl dispatch exit ;;
          esac
        else
          printf '%s\n' \
            "Bluetooth Settings" \
            "Bluetooth Quick Connect" \
            "Network Settings" \
            "WiFi Quick Connect" \
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

    ".config/hypr/scripts/cheatsheet.sh" = {
      text = ''
        #!/usr/bin/env bash
        notify-send -t 20000 "Hyprland Keybinds" "$(cat ~/.config/hypr/keybinds.txt)"
      '';
      executable = true;
    };

    ".config/hypr/keybinds.txt".text = ''
      HYPRLAND KEYBINDS (Corne 40%)
      ==============================

      FOCUS:
        Super + h/j/k/;        focus left/down/up/right

      WORKSPACES:
        Super + ,              previous workspace
        Super + .              next workspace
        Super Shift + ,        move window to prev workspace
        Super Shift + .        move window to next workspace

      WINDOW OPS:
        Super Shift + h/j/k/;  move window in direction
        Super + B              resize mode (hjkl to resize, ESC/Enter to exit)
        Super + T              toggle split layout
        Super + V              toggle floating
        Super + C              close window

      LAUNCH:
        Super + Q    terminal        Super + E    file manager
        Super + R    rofi launch     Super + S    scratchpad
        Super + /    show this cheatsheet

      SYSTEM:
        Super + L    lock screen
        Super + M    exit Hyprland
    '';
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
