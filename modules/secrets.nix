{ ... }:
{
  nixos.modules.desktop = {
    sops = {
      age.keyFile = "/home/lucid/.secrets/age.agekey";
      defaultSopsFile = ../secrets/secrets.yaml;
      secrets = {
        tailscale-auth-key = { };
      };
    };
  };
}
