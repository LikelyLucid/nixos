{ inputs, ... }:
{
  nixos.modules.desktop =
    { config, pkgs, ... }:
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

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

      systemd.services.hermes-agent.environment = {
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
        DISPLAY = ":0";
        WAYLAND_DISPLAY = "wayland-1";
        XDG_RUNTIME_DIR = "/run/user/1000";
        YDOTOOL_SOCKET = "/run/user/1000/.ydotool_socket";
      };
    };
}
