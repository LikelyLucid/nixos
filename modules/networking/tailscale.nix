{ config, pkgs, ... }:
{
  ############################################
  # TAILSCALE
  ############################################
  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
    authKeyFile = config.sops.secrets.tailscale-auth-key.path;
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--exit-node=100.75.156.101"
      "--exit-node-allow-lan-access"
    ];
  };
}
