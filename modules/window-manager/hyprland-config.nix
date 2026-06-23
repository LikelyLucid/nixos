{
  config,
  pkgs,
  dotfiles,
  ...
}:
let
  wallpaper_path = "/home/lucid/dotfiles/media/wallpapers/wallpaper.jpg";
  hyprland_config =
    builtins.replaceStrings
      [
        "$fileManager = $terminal -- yazi"
        ''$menu = rofi -show combi -combi-modes "window,run,ssh" -modes combi''
        "exec-once = waybar & hyprpaper & hypridle"
        "    pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below\n"
        "bind = $mainMod, J, togglesplit, # dwindle"
        "windowrule = suppressevent maximize, class:.*"
        "windowrule = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
      ]
      [
        "$fileManager = nemo"
        ''$menu = rofi -show drun -modi "drun,run,window,system:${config.home.homeDirectory}/.config/hypr/scripts/rofi-system.sh"''
        "exec-once = ${pkgs.waybar}/bin/waybar"
        ""
        "bind = $mainMod, T, layoutmsg, togglesplit # dwindle"
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
    source = ~/.config/hypr/wallust-colors.conf

    $terminal = ghostty
    $fileManager = nemo

    exec-once = ~/.config/hypr/scripts/wallust-apply.sh
    exec-once = hyprpaper
    exec-once = nm-applet &
    exec-once = blueman-applet &
    exec-once = systemctl --user restart swaync.service
    exec-once = systemctl --user start tray.target
    exec-once = systemctl --user restart kdeconnect-indicator.service
    exec-once = kdeconnectd
    exec-once = wl-paste --watch cliphist store

    # Clipboard history
    bind = $mainMod SHIFT, V, exec, cliphist list | rofi -dmenu -p "Clipboard" | cliphist decode | wl-copy

    # Screenshot tools
    bind = , Print, exec, grim -g "$(slurp)" - | swappy -f -
    bind = SHIFT, Print, exec, grim - | swappy -f -

    # === CORNE-FRIENDLY KEYBINDS (40%, no number row) ===
    # Home-row window focus
    bind = $mainMod, h, movefocus, l
    bind = $mainMod, j, movefocus, d
    bind = $mainMod, k, movefocus, u
    bind = $mainMod, l, movefocus, r

    # comma/period for workspace cycling (base-layer keys on Corne)
    bind = $mainMod, comma, workspace, e-1
    bind = $mainMod, period, workspace, e+1
    bind = $mainMod SHIFT, comma, movetoworkspace, e-1
    bind = $mainMod SHIFT, period, movetoworkspace, e+1

    # Move window within workspace (swap direction)
    bind = $mainMod SHIFT, h, movewindow, l
    bind = $mainMod SHIFT, j, movewindow, d
    bind = $mainMod SHIFT, k, movewindow, u
    bind = $mainMod SHIFT, l, movewindow, r

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
    ".config/hypr/scripts/wallust-apply.sh" = {
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        wallpaper="${wallpaper_path}"
        wallust -d /home/lucid/dotfiles/wallust run "$wallpaper"
        hyprctl hyprpaper wallpaper ",$wallpaper" 2>/dev/null || true
        pkill -SIGUSR2 -x .waybar-wrapped 2>/dev/null || pkill -SIGUSR2 -x waybar 2>/dev/null || true
        swaync-client -rs 2>/dev/null || true
        hyprctl reload 2>/dev/null || true
      '';
      executable = true;
    };

    ".local/bin/set-wallpaper" = {
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        if [ "$#" -ne 1 ]; then
          echo "usage: set-wallpaper /path/to/image" >&2
          exit 2
        fi
        install -m 0644 "$1" ${wallpaper_path}
        ~/.config/hypr/scripts/wallust-apply.sh
      '';
      executable = true;
    };

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

    ".config/hypr/scripts/caffinate.sh" = {
      text = ''
        #!/usr/bin/env bash
        if systemctl --user is-active hypridle &>/dev/null; then
          systemctl --user stop hypridle
          notify-send "☕ Caffinate ON" "System will not lock or sleep"
        else
          systemctl --user start hypridle
          notify-send "☕ Caffinate OFF" "Normal idle behavior restored"
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

    ".config/hypr/hyprlock.conf".text = ''
      source = ~/.config/hypr/wallust-hyprlock.conf

      background {
        monitor =
        path = ${wallpaper_path}
        blur_passes = 3
        blur_size = 8
      }

      input-field {
        monitor =
        size = 300, 60
        outline_thickness = 2
        dots_size = 0.2
        dots_spacing = 0.35
        outer_color = $wallust_accent
        inner_color = $wallust_bg_clear
        font_color = $wallust_fg
        fade_on_empty = false
        placeholder_text = <i>password</i>
        fail_text = <i>try again</i>
        fail_color = $wallust_fail
        position = 0, -80
        halign = center
        valign = center
      }

      label {
        monitor =
        text = cmd[update:1000] date +"%H:%M"
        color = $wallust_fg
        font_size = 72
        font_family = JetBrains Mono Nerd Font
        position = 0, 120
        halign = center
        valign = center
      }

      label {
        monitor =
        text = Welcome back, Arthur
        color = $wallust_accent
        font_size = 20
        font_family = JetBrains Mono Nerd Font
        position = 0, 45
        halign = center
        valign = center
      }
    '';

    ".config/hypr/keybinds.txt".text = ''
      HYPRLAND KEYBINDS (Corne 40%)
      ==============================

      FOCUS:
        Super + h/j/k/l        focus left/down/up/right

      WORKSPACES:
        Super + ,              previous workspace
        Super + .              next workspace
        Super Shift + ,        move window to prev workspace
        Super Shift + .        move window to next workspace

      WINDOW OPS:
        Super Shift + h/j/k/l  move window in direction
        Super + B              resize mode (hjkl to resize, ESC/Enter to exit)
        Super + T              toggle split layout
        Super + V              toggle floating
        Super + C              close window

      LAUNCH:
        Super + Q    terminal        Super + E    file manager
        Super + R    rofi launch     Super + S    scratchpad
        Super + /    show this cheatsheet

      SYSTEM:
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
