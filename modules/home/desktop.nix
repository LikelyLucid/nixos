{ ... }:
{
  homeManager.modules.desktop =
    { lib, pkgs, ... }:
    let
      home_dir = "/home/lucid";
    in
    {
      sops.age.keyFile = "${home_dir}/.secrets/age.agekey";

      ############################################
      # NEMO FILE MANAGER (riced with wallust)
      ############################################
      dconf.settings = {
        "org/blueman/general" = {
          # Keep Bluetooth auto-connect behavior without connection popups.
          plugin-list = [
            "!ConnectionNotifier"
            "NetUsage"
          ];
        };
        "org/blueman/plugins/autoconnect".services = map lib.hm.gvariant.mkTuple [
          [
            "3C:B0:ED:50:85:8A"
            "00000000-0000-0000-0000-000000000000"
          ]
          [
            "9C:FB:77:8A:67:D0"
            "00000000-0000-0000-0000-000000000000"
          ]
          [
            "EE:43:49:E1:10:8A"
            "00000000-0000-0000-0000-000000000000"
          ]
          [
            "24:11:53:F5:C8:DB"
            "00000000-0000-0000-0000-000000000000"
          ]
        ];
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
        cua-driver # Native Wayland computer-use MCP
        noto-fonts
        noto-fonts-cjk-sans
        usbutils
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
        (spotify-player.override { withAudioBackend = "pulseaudio"; })
        wallust
        waybar
        eww
        pkgs.hyprland-canvas
        beeper
      ];

      fonts.fontconfig.defaultFonts.sansSerif = [ "Noto Sans" ];
      # Hokum's `font "mono"` resolves through fontconfig; keep it on the
      # workstation typeface instead of falling back to DejaVu.
      fonts.fontconfig.defaultFonts.monospace = [ "JetBrains Mono" ];

      ############################################
      # SYNCTHING (desktop only)
      ############################################
      services.syncthing = {
        enable = true;
        package = pkgs.syncthing;
        guiAddress = "127.0.0.1:8384";
        overrideDevices = true;
        overrideFolders = true;
        settings = {
          devices = {
            lucid-server = {
              id = "6XWWGNN-R7HBLRL-CHGQSTV-BYLYWXP-YTIXXLG-EEXRZLN-2EDHEAF-JSRIDAP";
              name = "lucid-server";
            };
            bigboy = {
              id = "XHF4Y4B-QZM2XII-R7W5IG2-DXGQONP-DHPYDJH-OEGHNVR-7S6MXIL-R5LFQAY";
              name = "bigboy";
            };
          };
          folders."Vault-V2" = {
            id = "Vault-V2";
            path = "${home_dir}/Documents/Vault";
            label = "Vault-V2 - Obsidian";
            devices = [ "lucid-server" ];
            versioning = {
              type = "simple";
              params.keep = 10;
            };
          };
          gui.theme = "black";
        };
      };

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
      # NOTIFICATIONS
      ############################################
      # Hokum (modules/desktop/hokum.nix) is the notification daemon.
      home.file.".local/bin/notify-send" = {
        source = "${pkgs.libnotify}/bin/notify-send";
        executable = true;
      };
    };
}
