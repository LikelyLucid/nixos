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
    $fileManager = ghostty -- yazi
    
    exec-once = hyprpaper &
    exec-once = nm-applet &
    exec-once = blueman-applet &
    exec-once = dunst &
    exec-once = cliphist daemon &
    
    # System menu (rofi)
    bind = SUPER, S, exec, ~/.config/hypr/scripts/system-menu.sh
    
    # Clipboard history
    bind = SUPER, V, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy
    
    # Screenshot tools
    bind = , Print, exec, grim -g "$(slurp)" - | swappy -f -
    bind = SHIFT, Print, exec, grim - | swappy -f -
  '';

  # System menu script
  home.file.".config/hypr/scripts/system-menu.sh" = {
    text = ''
      #!/usr/bin/env bash
      
      options=(
        "\U000f0102  Bluetooth"
        "\U000f0268  WiFi"
        "\U000f056e  Audio"
        "\U000f0339  Monitors"
        "\U000f0e51  Screenshot (area)"
        "\U000f0e51  Screenshot (full)"
        "\U000f06a9  Sleep"
        "\U000f049f  Reboot"
        "\U000f049c  Shutdown"
      )
      
      actions=(
        "blueman-manager"
        "nm-connection-editor"
        "pavucontrol"
        "nwg-displays"
        "grim -g \"$(slurp)\" - | swappy -f -"
        "grim - | swappy -f -"
        "systemctl suspend"
        "systemctl reboot"
        "systemctl poweroff"
      )
      
      chosen=$(printf "%s\n" "''${options[@]}" | rofi -dmenu -i -p "System")
      
      if [ -n "$chosen" ]; then
        for i in "''${!options[@]}"; do
          if [ "''${options[$i]}" = "$chosen" ]; then
            eval "''${actions[$i]}"
            break
          fi
        done
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
