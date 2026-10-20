{ ... }:
{
  nixos.modules.desktop =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs; [
        jetbrains-mono
        nerd-fonts.jetbrains-mono
      ];
    };

  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      gtk_theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      desktop_theme_toggle = pkgs.writeShellApplication {
        name = "desktop-theme-toggle";
        runtimeInputs = with pkgs; [
          glib
          libnotify
        ];
        text = ''
          set -euo pipefail

          interface=org.gnome.desktop.interface
          current_scheme=$(gsettings get "$interface" color-scheme)

          case "$current_scheme" in
            *prefer-dark*)
              next_scheme=prefer-light
              next_gtk_theme=adw-gtk3
              next_icon_theme=Papirus
              next_label='Light'
              ;;
            *)
              next_scheme=prefer-dark
              next_gtk_theme=adw-gtk3-dark
              next_icon_theme=Papirus-Dark
              next_label='Dark'
              ;;
          esac

          gsettings set "$interface" color-scheme "$next_scheme"
          gsettings set "$interface" gtk-theme "$next_gtk_theme"
          gsettings set "$interface" icon-theme "$next_icon_theme"
          notify-send -a Theme -i preferences-desktop-theme "Desktop theme" "$next_label mode" || true
        '';
      };
    in
    {
      gtk = {
        enable = true;
        font = {
          name = "JetBrains Mono";
          size = 11;
        };
        theme = gtk_theme;
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
        cursorTheme = {
          name = "Bibata-Modern-Ice";
          package = pkgs.bibata-cursors;
          size = 24;
        };
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = true;
          gtk-enable-primary-paste = false;
        };
        # Libadwaita applications follow the dconf color scheme directly;
        # injecting a GTK 4 theme or legacy dark-theme key causes warnings.
        gtk4.extraConfig.gtk-enable-primary-paste = false;
        gtk4.theme = null;
      };

      qt = {
        enable = true;
        platformTheme.name = "gtk3";
        style.name = "adwaita-dark";
      };

      home.pointerCursor = {
        enable = true;
        name = "Bibata-Modern-Ice";
        package = pkgs.bibata-cursors;
        size = 24;
        gtk.enable = true;
        x11.enable = true;
        hyprcursor.enable = true;
      };

      home.packages = [ desktop_theme_toggle ];

      dconf.settings."org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-enable-primary-paste = false;
      };
    };
}
