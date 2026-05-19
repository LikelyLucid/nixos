{ config, pkgs, ... }:
{
  ############################################
  # TAILSCALE
  ############################################
  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
    authKeyFile =
      # Try Bitwarden first, fall back to SOPS
      if config.bitwarden.enable or false && config.bitwarden.secretPaths ? tailscale-auth-key
      then config.bitwarden.secretPaths.tailscale-auth-key
      else if config.sops.secrets ? tailscale-auth-key then config.sops.secrets.tailscale-auth-key.path
      else null;
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--exit-node=100.75.156.101"
      "--exit-node-allow-lan-access"
    ];
  };
}
