{ config, pkgs, ... }:
{
  ############################################
  # TAILSCALE
  ############################################
  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
    authKeyFile = "/home/lucid/.config/tailscale-auth-key";
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--exit-node=100.75.156.101"
      "--exit-node-allow-lan-access"
    ];
  };
}
