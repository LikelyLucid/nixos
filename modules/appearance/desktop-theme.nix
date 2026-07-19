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
        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        # Libadwaita applications follow the dconf color scheme directly;
        # injecting a GTK 4 theme or legacy dark-theme key causes warnings.
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

      dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    };
}
