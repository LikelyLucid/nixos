{ config, pkgs, lib, ... }:

let
  cfg = config.networking.tailscale;
in
{
  options.networking.tailscale.allowedSSIDs = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "List of SSIDs to automatically connect to Tailscale on.";
  };

  config = {
    services.tailscale.enable = true;
    services.tailscale.package = pkgs.tailscale;
    services.tailscale.authKeyFile = config.sops.secrets.tailscale-auth-key.path;
    services.tailscale.useRoutingFeatures = "client";
    services.tailscale.extraUpFlags = [
      "--exit-node=100.75.156.101"
      "--exit-node-allow-lan-access"
    ];

    networking.networkmanager.dispatcherScripts = [
      {
        type = "pre-up";
        source = pkgs.writeShellScript "tailscale-autoconnect" ''
          SSID=$(nmcli -t -f active,ssid dev wifi | egrep '^yes' | cut -d\' -f2)
          ALLOWED_SSIDS=("${lib.escapeShellArgs cfg.allowedSSIDs}")

          if [[ "''${ALLOWED_SSIDS[*]} " =~ " ''${SSID} " ]]; then
            ${pkgs.tailscale}/bin/tailscale up
          else
            ${pkgs.tailscale}/bin/tailscale down
          fi
        '';
      }
    ];
  };
}
