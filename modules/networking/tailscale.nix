{ config, pkgs, ... }:
{
  ############################################
  # TAILSCALE
  ############################################
  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
    authKeyFile = config.sops.secrets.tailscale-auth-key.path;
    extraSetFlags = [
      "--ssh"
      "--operator=lucid"
    ];
    useRoutingFeatures = "client";
  };
}
