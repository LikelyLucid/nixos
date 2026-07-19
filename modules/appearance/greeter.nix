{ inputs, ... }:
{
  nixos.modules.desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hyprland = lib.getExe config.programs.hyprland.package;
      uwsm = lib.getExe pkgs.uwsm;
      uwsm_session =
        (pkgs.writeTextDir "share/wayland-sessions/hyprland.desktop" ''
          [Desktop Entry]
          Name=Hyprland
          Comment=Hyprland managed by UWSM
          Exec=${uwsm} start -e -D Hyprland -F ${hyprland}
          TryExec=${uwsm}
          DesktopNames=Hyprland
          Type=Application
        '').overrideAttrs
          {
            passthru.providedSessions = [ "hyprland" ];
          };
      wallust_palette = builtins.readFile "${inputs.dotfiles}/waybar/colors-wallust.css";
    in
    {
      services.displayManager.sessionPackages = lib.mkForce [ uwsm_session ];

      programs.regreet = {
        enable = true;
        cageArgs = [
          "-s"
          "-d"
          "-m"
          "last"
        ];

        settings = {
          skip_selection = true;

          background = {
            path = "${inputs.dotfiles}/media/wallpapers/wallpaper.jpg";
            fit = "Cover";
          };

          appearance.greeting_msg = "Welcome back, Arthur";

          commands = {
            reboot = [
              "systemctl"
              "reboot"
            ];
            poweroff = [
              "systemctl"
              "poweroff"
            ];
          };

          GTK = {
            application_prefer_dark_theme = true;
            cursor_blink = true;
          };

          widget.clock = {
            format = "%H:%M";
            resolution = "1s";
            label_width = 120;
          };
        };

        font = {
          name = "JetBrains Mono";
          package = pkgs.jetbrains-mono;
          size = 13;
        };

        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };

        cursorTheme = {
          name = "Bibata-Modern-Ice";
          package = pkgs.bibata-cursors;
        };

        extraCss = ''
          ${wallust_palette}

          window {
            color: @foreground;
            font-family: "JetBrains Mono";
          }

          frame.background {
            background-color: alpha(@color0, 0.90);
            color: @foreground;
            border: 1px solid alpha(@color8, 0.72);
            border-radius: 10px;
            box-shadow: 0 16px 48px alpha(@color0, 0.68);
          }

          frame.background > grid {
            padding: 8px;
          }

          label {
            color: @foreground;
          }

          entry,
          passwordentry,
          combobox button {
            min-height: 44px;
            padding: 0 12px;
            color: @foreground;
            background-color: alpha(@color0, 0.82);
            border: 1px solid alpha(@color8, 0.72);
            border-radius: 7px;
          }

          button {
            min-height: 40px;
            padding: 0 14px;
            color: @foreground;
            background-color: alpha(@color0, 0.82);
            border: 1px solid alpha(@color8, 0.72);
            border-radius: 7px;
          }

          button:hover {
            color: @color0;
            background-color: @color8;
          }

          button:focus {
            outline-color: @color7;
            outline-style: solid;
            outline-width: 2px;
            outline-offset: 2px;
          }

          button.suggested-action {
            color: @color0;
            background-color: @color7;
            border-color: @color7;
            font-weight: 700;
          }

          button.destructive-action:hover {
            color: @color0;
            background-color: @color1;
            border-color: @color1;
          }

          infobar {
            color: @foreground;
            background-color: alpha(@color0, 0.94);
            border: 1px solid alpha(@color8, 0.72);
            border-radius: 7px;
          }
        '';
      };
    };
}
