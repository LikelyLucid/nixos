{ ... }:
{
  nixos.modules.desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
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

      # Authentication continues in the background instead of gating multi-user.target.
      systemd.services.tailscaled-autoconnect.serviceConfig.Type = lib.mkForce "exec";
    };
}
