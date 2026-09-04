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
        # Hermes 0.20 launches CUA as bare `mcp`; v0.22 requires an
        # explicit daemon endpoint for native Wayland window discovery.
        if [ "''${1:-}" = "mcp" ]; then
          shift
          exec ${pkgs.cua-driver}/bin/cua-driver mcp \
            --socket /home/lucid/.cache/cua-driver/cua-driver.sock "$@"
        fi
        exec ${pkgs.cua-driver}/bin/cua-driver "$@"
      '';

      # Upstream desktop.nix hardcodes the electron-headers hash for their
      # nixpkgs-unstable electron version. Our pinned nixpkgs ships a
      # different electron 43.4.1 whose headers tarball has a different hash.
      # Override just the desktop derivation's pkgs to fix the fetchurl.
      hermes_desktop = inputs.hermes-agent.packages.${pkgs.system}.desktop.override {
        pkgs = pkgs.extend (
          _final: prev: {
            fetchurl =
              args: prev.fetchurl (args // { sha256 = "sha256-CyzcARd1+GhWr8ED7HBYW2MYD+tgetqZFMkaivaGvw0="; });
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
            YDOTOOL_SOCKET = "/run/user/1000/.ydotool_socket";
          };
        };
        settings = {
          agent.image_input_mode = "auto";
          approvals.mode = "smart";
          computer_use.no_overlay = true;
          delegation.max_concurrent_children = 5;
          display.streaming = true;
          display.pet = {
            enabled = false;
            slug = "nightly-fox";
          };
          model = {
            default = "mimo-v2.5";
            provider = "opencode-go";
          };
          auxiliary.vision = {
            provider = "auto";
            model = "auto";
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
        YDOTOOL_SOCKET = "/run/user/1000/.ydotool_socket";
        HERMES_MANAGED = lib.mkForce "false";
      };

      systemd.services.hermes-agent.serviceConfig.UnsetEnvironment = [ "DISPLAY" ];

      environment.sessionVariables.HERMES_CUA_DRIVER_CMD = "${cua_driver_hermes}/bin/cua-driver-hermes";
    };
}
