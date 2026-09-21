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
      cua_driver_hermes = pkgs.writeShellScriptBin "cua-driver-hermes" ''
        # Hermes connects to the shared Cua Driver daemon so native Wayland
        # discovery and driver state are owned by one long-lived process.
        if [ "''${1:-}" = "mcp" ]; then
          shift
          exec ${pkgs.cua-driver}/bin/cua-driver mcp \
            --socket /home/lucid/.cache/cua-driver/cua-driver.sock "$@"
        fi
        exec ${pkgs.cua-driver}/bin/cua-driver "$@"
      '';

      # Upstream desktop.nix hardcodes a stale electron-headers hash. Our
      # pinned nixpkgs ships Electron 43.6.0 whose headers tarball has a
      # different hash. Override only that URL: changing every fetchurl in the
      # desktop package would corrupt unrelated source downloads.
      hermes_desktop = inputs.hermes-agent.packages.${pkgs.system}.desktop.override {
        pkgs = pkgs.extend (
          _final: prev: {
            fetchurl =
              args:
              prev.fetchurl (
                args
                //
                  lib.optionalAttrs
                    (
                      (args.url or null)
                      == "https://artifacts.electronjs.org/headers/dist/v43.6.0/node-v43.6.0-headers.tar.gz"
                    )
                    {
                      sha256 = "sha256-xDgc5PpkcLpWHnlqVcjBD3SxJKtkUoSGLnJaSSrxJtI=";
                    }
              );
          }
        );
      };
    in
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      environment.systemPackages = [
        cua_driver_hermes
        hermes_desktop
      ];

      sops.secrets.hermes-env = {
        owner = "lucid";
        group = "users";
      };

      # Hermes may have been initialized by an older service user. Normalize
      # the existing state tree before the gateway starts as lucid.
      systemd.tmpfiles.rules = [
        "Z /var/lib/hermes/.hermes - lucid users -"
      ];

      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;
        user = "lucid";
        group = "users";
        createUser = false;
        extraPackages = [ pkgs.cua-driver ];
        environmentFiles = [ config.sops.secrets.hermes-env.path ];
        mcpServers.computer-use-linux = {
          command = "${pkgs.cua-driver}/bin/cua-driver";
          args = [
            "mcp"
            "--socket"
            "/home/lucid/.cache/cua-driver/cua-driver.sock"
          ];
          env = {
            CUA_DRIVER_RS_ENABLE_WAYLAND = "1";
            DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
            WAYLAND_DISPLAY = "wayland-1";
            XDG_RUNTIME_DIR = "/run/user/1000";
          };
        };
      };

      # Keep the user config writable. The upstream activation script deep-merges
      # declarative settings into it, so rebuilds preserve all other user choices.
      system.activationScripts.hermes-agent-user-config = lib.stringAfter [ "hermes-agent-setup" ] ''
        rm -f /var/lib/hermes/.hermes/.managed
      '';

      systemd.services.hermes-agent.environment = {
        CUA_DRIVER_RS_ENABLE_WAYLAND = "1";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
        HERMES_CUA_DRIVER_CMD = "${cua_driver_hermes}/bin/cua-driver-hermes";
        WAYLAND_DISPLAY = "wayland-1";
        XDG_RUNTIME_DIR = "/run/user/1000";
        HERMES_MANAGED = lib.mkForce "false";
      };

      systemd.services.hermes-agent.serviceConfig.UnsetEnvironment = [ "DISPLAY" ];

      environment.sessionVariables.HERMES_CUA_DRIVER_CMD = "${cua_driver_hermes}/bin/cua-driver-hermes";
    };

  homeManager.modules.desktop =
    { pkgs, ... }:
    {
      systemd.user.services.cua-driver = {
        Unit = {
          Description = "Cua Driver Wayland daemon";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /home/lucid/.cache/cua-driver";
          ExecStart = "${pkgs.cua-driver}/bin/cua-driver serve --socket /home/lucid/.cache/cua-driver/cua-driver.sock --no-overlay";
          Environment = [
            "CUA_DRIVER_RS_ENABLE_WAYLAND=1"
            "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
            "WAYLAND_DISPLAY=wayland-1"
            "XDG_RUNTIME_DIR=/run/user/1000"
          ];
          UnsetEnvironment = [ "DISPLAY" ];
          Restart = "on-failure";
          RestartSec = 2;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
