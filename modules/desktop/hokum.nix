{ ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    let
      # Hokum ships prebuilt desktop builds; there is no upstream Nix package.
      hokum = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
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
        # Vulkan is dlopen'd, so autoPatchelf cannot discover it from DT_NEEDED.
        # Without the loader on RUNPATH the GPU backend falls back to nothing and
        # Hokum cannot draw its layer surfaces at all.
        runtimeDependencies = [ pkgs.vulkan-loader ];

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
    in
    {
      home.packages = [ hokum ];

      # config.kdl is NOT declared here: Hokum rewrites it when DND or the theme
      # changes, so a read-only store symlink would break `hokum dnd` and the
      # settings window. modules/dotfiles.nix links ~/dotfiles/hokum instead.
      # The theme is generated from the wallpaper palette by wallust, so
      # palette changes reach Hokum live. Source template:
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

      home.file.".local/share/dbus-1/services/app.hokum.Notifications.service" = {
        force = true;
        text = ''
          [D-BUS Service]
          Name=org.freedesktop.Notifications
          Exec=${hokum}/bin/hokum service
          SystemdService=hokum.service
        '';
      };

      home.file.".local/share/applications/hokum.desktop" = {
        force = true;
        text = ''
          [Desktop Entry]
          Type=Application
          Name=Hokum
          GenericName=Notification Settings
          Comment=Style and configure your notifications
          Exec=${hokum}/bin/hokum
          Icon=preferences-desktop-notification
          Terminal=false
          StartupNotify=true
          Categories=Settings;DesktopSettings;
          Keywords=notifications;notification;daemon;do not disturb;
        '';
      };
    };
}
