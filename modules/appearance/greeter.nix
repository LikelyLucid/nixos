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
      hyprland_session = "${config.programs.hyprland.package}/share/wayland-sessions/hyprland.desktop";
      uwsm = lib.getExe pkgs.uwsm;
      uwsm_session =
        (pkgs.writeTextDir "share/wayland-sessions/hyprland.desktop" ''
          [Desktop Entry]
          Name=Hyprland
          Comment=Hyprland managed by UWSM
          Exec=${uwsm} start -e -D Hyprland -g -1 ${hyprland_session}
          TryExec=${uwsm}
          DesktopNames=Hyprland
          Type=Application
        '').overrideAttrs
          {
            passthru.providedSessions = [ "hyprland" ];
          };
      cage_args = [
        "-s"
        "-d"
        "-m"
        "last"
      ];
      regreet = lib.getExe config.programs.regreet.package;
      regreet_state = pkgs.writeText "regreet-state.toml" ''
        last_user = "lucid"

        [user_to_last_sess]
        lucid = "Hyprland"
      '';
      greeter_background =
        pkgs.runCommand "regreet-background.jpg" { nativeBuildInputs = [ pkgs.imagemagick ]; }
          ''
            magick ${inputs.dotfiles}/media/wallpapers/wallpaper.jpg \
              -filter Gaussian \
              -blur 0x8 \
              -brightness-contrast -8x0 \
              "$out"
          '';
      wallust_palette = builtins.readFile "${inputs.dotfiles}/waybar/colors-wallust.css";
    in
    {
      services.displayManager.sessionPackages = lib.mkForce [ uwsm_session ];

      services.greetd.settings.default_session = {
        command = "${pkgs.coreutils}/bin/env GTK_USE_PORTAL=0 GDK_DEBUG=no-portals ${pkgs.dbus}/bin/dbus-run-session ${lib.getExe pkgs.cage} ${lib.escapeShellArgs cage_args} -- ${regreet}";
        user = "greeter";
      };

      systemd.services.greetd.preStart = ''
        ${pkgs.coreutils}/bin/install -D \
          -o greeter \
          -g greeter \
          -m 0644 \
          ${regreet_state} \
          /var/lib/regreet/state.toml
      '';

      programs.regreet = {
        enable = true;
        cageArgs = cage_args;

        settings = {
          skip_selection = true;

          background = {
            path = greeter_background;
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
            label_width = 300;
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
            color: @foreground;
            background-color: transparent;
            border: none;
            box-shadow: none;
          }

          frame.background > grid {
            padding: 22px;
            background-color: alpha(@color0, 0.88);
            border: 1px solid alpha(@color8, 0.64);
            border-radius: 10px;
            box-shadow: 0 16px 48px alpha(@color0, 0.72);
          }

          frame.background > label {
            padding: 16px 28px;
            color: @foreground;
            background-color: alpha(@color0, 0.72);
            border: 1px solid alpha(@color8, 0.56);
            border-radius: 10px;
            font-size: 56px;
            font-weight: 700;
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
            background-color: alpha(@color0, 0.78);
            border: 1px solid alpha(@color8, 0.64);
            border-radius: 7px;
          }

          entry:focus,
          passwordentry:focus,
          combobox button:focus {
            border-color: @color7;
            outline-color: @color7;
            outline-style: solid;
            outline-width: 2px;
            outline-offset: 2px;
          }

          combobox:disabled button {
            color: @color8;
            background-color: transparent;
            background-image: none;
            border-color: transparent;
          }

          combobox:disabled arrow,
          button.toggle:disabled {
            min-width: 0;
            padding: 0;
            opacity: 0;
            border: none;
          }

          button {
            min-height: 40px;
            padding: 0 14px;
            color: @foreground;
            background-color: alpha(@color0, 0.78);
            background-image: none;
            border: 1px solid alpha(@color8, 0.64);
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

          button:disabled {
            opacity: 0.55;
          }

          button.suggested-action {
            color: @color0;
            background-color: @color7;
            background-image: none;
            border-color: @color7;
            font-weight: 700;
          }

          button.destructive-action {
            color: @color8;
            background-color: alpha(@color0, 0.72);
            background-image: none;
            border-color: alpha(@color8, 0.48);
          }

          button.destructive-action:hover {
            color: @color0;
            background-color: @color1;
            background-image: none;
            border-color: @color1;
          }

          infobar {
            color: @foreground;
            background-color: alpha(@color0, 0.82);
            border: 1px solid alpha(@color8, 0.56);
            border-radius: 7px;
          }

          infobar.info {
            opacity: 0;
          }

          infobar.error {
            color: @color0;
            background-color: @color1;
            opacity: 1;
          }
        '';
      };
    };
}
