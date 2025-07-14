{ config, pkgs, ... }:

{
  services.tailscale.enable = true;
  services.tailscale.package = pkgs.tailscale;
  services.tailscale.authKeyFile = config.sops.secrets.tailscale-auth-key.path;
  services.tailscale.extraUpFlags = [
    "--exit-node=lucidsserver"
    "--exit-node-allow-lan-access"
  ];
}