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
      # The HUD window (chrome-free floating chat) shares the `hermes`/`Hermes`
      # class+title with the main window, so Hyprland cannot target it with a
      # window rule. Patch the bundled main process to give the HUD a distinct
      # title; hyprland-config.nix then floats and pins it above everything.
      hermesDesktop = inputs.hermes-agent.packages.${pkgs.system}.desktop.overrideAttrs (old: {
        installPhase = old.installPhase + ''
          substituteInPlace $out/share/hermes-desktop/dist/electron-main.mjs \
            --replace-fail '...hudBounds(),' 'title: "Hermes HUD", ...hudBounds(),'

          substituteInPlace $out/share/hermes-desktop/dist/electron-main.mjs \
            --replace-fail \
              '  startHudCursorFeed(win);' \
              $'  startHudCursorFeed(win);\n  win.setTitle("Hermes HUD");\n  win.on("page-title-updated", (event) => event.preventDefault());'
        '';
      });
    in
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      environment.systemPackages = [ hermesDesktop ];

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
        extraPackages = [ pkgs.computer-use-linux ];
        environmentFiles = [ config.sops.secrets.hermes-env.path ];
        mcpServers.computer-use-linux = {
          command = "${pkgs.computer-use-linux}/bin/computer-use-linux";
          args = [ "mcp" ];
          env = {
            DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
            DISPLAY = ":0";
            WAYLAND_DISPLAY = "wayland-1";
            XDG_RUNTIME_DIR = "/run/user/1000";
            YDOTOOL_SOCKET = "/run/user/1000/.ydotool_socket";
          };
        };
        settings = {
          agent.image_input_mode = "auto";
          approvals.mode = "smart";
          browser.cdp_url = "http://127.0.0.1:9222";
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
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
        DISPLAY = ":0";
        WAYLAND_DISPLAY = "wayland-1";
        XDG_RUNTIME_DIR = "/run/user/1000";
        YDOTOOL_SOCKET = "/run/user/1000/.ydotool_socket";
        HERMES_MANAGED = lib.mkForce "false";
      };
    };
}
