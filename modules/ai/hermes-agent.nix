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
          agent.disabled_toolsets = [ "computer_use" ];
          model = {
            default = "kimi-k2.7-code";
            provider = "opencode-go";
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
