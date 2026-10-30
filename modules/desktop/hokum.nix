{ getSystem, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      # Hokum ships prebuilt desktop builds; there is no upstream nixpkgs package.
      packages.hokum = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "hokum";
        version = "0.1.2";

        src = pkgs.fetchurl {
          url = "https://github.com/anomalyco/hokum/releases/download/v${finalAttrs.version}/hokum-${finalAttrs.version}-linux-x64";
          hash = "sha256-DF2utluXTttvheOFSjPhcpRwwCG85dg8agSEuYfE/f4=";
        };

        dontUnpack = true;
        nativeBuildInputs = [ pkgs.autoPatchelfHook ];
        buildInputs = [
          pkgs.stdenv.cc.cc.lib
          pkgs.libxkbcommon
        ];
        # Both libraries are dlopen'd, so autoPatchelf cannot discover them from
        # DT_NEEDED. Without the Vulkan loader Hokum cannot draw at all; without
        # libwayland-client winit panics with "The wayland library could not be
        # loaded" and the daemon never owns org.freedesktop.Notifications.
        runtimeDependencies = [
          pkgs.vulkan-loader
          pkgs.wayland
        ];

        installPhase = ''
          runHook preInstall
          install -Dm755 ${finalAttrs.src} $out/bin/hokum
          runHook postInstall
        '';

        meta = {
          description = "Freedesktop notification daemon for Wayland layer-shell compositors";
          homepage = "https://hokum.app";
          license = pkgs.lib.licenses.mit;
          platforms = [ "x86_64-linux" ];
          mainProgram = "hokum";
        };
      });
    };

  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      hokum = (getSystem pkgs.stdenv.hostPlatform.system).packages.hokum;
    in
    {
      home.packages = [ hokum ];

      # config.kdl is NOT declared here: Hokum rewrites it when DND or the theme
      # changes, so a read-only store symlink would break `hokum dnd` and the
      # settings window. modules/dotfiles.nix links ~/dotfiles/hokum instead.
      # The theme is generated from the wallpaper palette by wallust, so palette
      # changes reach Hokum live. Source template:
      # ~/dotfiles/wallust/templates/hokum.kdl

      # Hokum replaces swaync as the org.freedesktop.Notifications owner. The unit
      # is Type=dbus, so D-Bus activation lets the first notification start it.
      systemd.user.services.hokum = {
        Unit = {
          Description = "Hokum notification daemon (org.freedesktop.Notifications)";
          Documentation = [ "https://hokum.app" ];
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "dbus";
          BusName = "org.freedesktop.Notifications";
          ExecCondition = "/bin/sh -c 'test -n \"$WAYLAND_DISPLAY\"'";
          ExecStart = "${hokum}/bin/hokum service";
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      xdg.dataFile."dbus-1/services/app.hokum.Notifications.service".text = ''
        [D-BUS Service]
        Name=org.freedesktop.Notifications
        Exec=${hokum}/bin/hokum service
        SystemdService=hokum.service
      '';

      # `hokum` with no arguments opens the settings window, which is what the
      # launcher entry should do. Card appearance is theme-driven, not configured
      # here.
      xdg.desktopEntries.hokum = {
        name = "Hokum";
        genericName = "Notification Settings";
        comment = "Style and configure your notifications";
        exec = "${hokum}/bin/hokum";
        icon = "preferences-desktop-notification";
        terminal = false;
        categories = [
          "Settings"
          "DesktopSettings"
        ];
        settings.Keywords = "notifications;notification;daemon;do not disturb;";
      };
    };
}
