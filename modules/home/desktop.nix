{ ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      home_dir = "/home/lucid";
    in
    {
      sops.age.keyFile = "${home_dir}/.secrets/age.agekey";

      ############################################
      # NEMO FILE MANAGER (riced with wallust)
      ############################################
      dconf.settings = {
        "org/nemo/preferences" = {
          default-folder-viewer = "icon-view";
          show-location-entry = true;
          enable-delete = true;
          date-format = "locale";
        };
        "org/nemo/icon-view" = {
          default-zoom-level = "standard";
        };
        "org/nemo/window-state" = {
          start-with-sidebar = true;
          geometry = "1200x800+100+100";
        };
      };

      # Nemo as default file manager; terminal Neovim for text-like files.
      xdg.desktopEntries.nvim = {
        name = "Neovim";
        genericName = "Text Editor";
        exec = "ghostty -e nvim %F";
        terminal = false;
        mimeType = [
          "application/json"
          "application/toml"
          "application/x-shellscript"
          "application/x-yaml"
          "text/markdown"
          "text/plain"
          "text/x-markdown"
          "text/x-c"
          "text/x-c++"
          "text/x-go"
          "text/x-lua"
          "text/x-nix"
          "text/x-python"
          "text/x-rust"
        ];
        categories = [
          "Development"
          "TextEditor"
        ];
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "inode/directory" = "nemo.desktop";

          "application/json" = "nvim.desktop";
          "application/toml" = "nvim.desktop";
          "application/x-shellscript" = "nvim.desktop";
          "application/x-yaml" = "nvim.desktop";
          "text/markdown" = "nvim.desktop";
          "text/plain" = "nvim.desktop";
          "text/x-markdown" = "nvim.desktop";
          "text/x-c" = "nvim.desktop";
          "text/x-c++" = "nvim.desktop";
          "text/x-go" = "nvim.desktop";
          "text/x-lua" = "nvim.desktop";
          "text/x-nix" = "nvim.desktop";
          "text/x-python" = "nvim.desktop";
          "text/x-rust" = "nvim.desktop";

          "application/gzip" = "org.gnome.FileRoller.desktop";
          "application/vnd.rar" = "org.gnome.FileRoller.desktop";
          "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
          "application/x-bzip2" = "org.gnome.FileRoller.desktop";
          "application/x-compressed-tar" = "org.gnome.FileRoller.desktop";
          "application/x-tar" = "org.gnome.FileRoller.desktop";
          "application/x-xz" = "org.gnome.FileRoller.desktop";
          "application/zstd" = "org.gnome.FileRoller.desktop";
          "application/zip" = "org.gnome.FileRoller.desktop";
        };
      };

      ############################################
      # DESKTOP PACKAGES
      ############################################
      home.packages = with pkgs; [
        # Desktop Linux GUI packages
        cava
        hyprpaper
        (nemo-with-extensions.override {
          extensions = [
            nemo-preview
            nemo-seahorse
          ];
        })
        file-roller
        libnotify
        pavucontrol
        rofi
        spotify-player
        swaynotificationcenter
        wallust
        waybar
        pkgs.hyprland-canvas
        beeper
      ];

      ############################################
      # KDE CONNECT (desktop only)
      ############################################
      services.kdeconnect = {
        enable = true;
        indicator = true;
      };

      xdg.configFile."kdeconnect/4f91b463981d4e788fe49fb277df446e/kdeconnect_share/config" = {
        force = true;
        text = ''
          [General]
          incoming_path=${home_dir}/Desktop
        '';
      };

      ############################################
      # TAILSCALE SYSTRAY (desktop only)
      ############################################
      services.tailscale-systray = {
        enable = true;
        theme = "dark:nobg";
      };

      ############################################
      # GHOSTTY TERMINAL (with wallust colors)
      ############################################
      home.file.".config/ghostty/config" = {
        text = ''
          # Font
          font-family = JetBrains Mono Nerd Font
          font-size = 12

          # Window
          background-opacity = 0.9
          window-padding-x = 10
          window-padding-y = 10

          # Clipboard
          clipboard-read = allow
          clipboard-write = allow

          # Shell integration
          shell-integration = zsh

          # Wallust colors (auto-generated from wallpaper)
          config-file = /home/lucid/.config/ghostty/colors.conf
        '';
      };

      # Note: wallust templates/config come from dotfiles
      # Add ghostty template to your dotfiles wallust/templates/ folder manually

      ############################################
      # SWAYNC (notification center)
      ############################################
      xdg.configFile."swaync/config.json" = {
        text = ''
          {
            "$schema": "/etc/xdg/swaync/config.json",
            "positionX": "right",
            "positionY": "top",
            "layer": "overlay",
            "control-center-margin-top": 10,
            "control-center-margin-right": 10,
            "control-center-margin-bottom": 10,
            "control-center-margin-left": 0,
            "notification-2fa-action": true,
            "notification-inline-replies": true,
            "notification-window-width": 420,
            "notification-window-height": -1,
            "timeout": 5,
            "timeout-low": 3,
            "timeout-critical": 0,
            "fit-to-screen": true,
            "keyboard-shortcuts": true,
            "image-radius": 12
          }
        '';
      };

      home.file.".local/bin/notify-send" = {
        source = "${pkgs.libnotify}/bin/notify-send";
        executable = true;
      };

      systemd.user.services.swaync = {
        Unit = {
          Description = "Swaync notification daemon";
          Documentation = [ "https://github.com/ErikReider/SwayNotificationCenter" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
          Restart = "on-failure";
        };
      };

      # Swaync CSS is generated by wallust: ~/.config/swaync/style.css
      # Run 'wallust run' after rebuild to apply colors

    };
}
