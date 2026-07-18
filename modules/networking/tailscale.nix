{ ... }:
{
  nixos.modules.desktop =
    { config, pkgs, ... }:
    {
      ############################################
      # TAILSCALE
      ############################################
      services.tailscale = {
        enable = true;
        package = pkgs.tailscale;
        authKeyFile = config.sops.secrets.tailscale-auth-key.path;
        extraUpFlags = [
          "--ssh"
          "--exit-node=lucidsserver"
          "--operator=lucid"
        ];
        extraSetFlags = [
          "--ssh"
          "--operator=lucid"
        ];
        useRoutingFeatures = "client";
      };
    };
}
