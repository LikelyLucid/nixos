{ config, pkgs, ... }:

{
  sops = {
    age.keyFile = "/home/lucid/.secrets/age.agekey";
    defaultSopsFile = /home/lucid/nixos/secrets/secrets.yaml;
    secrets = {
      tailscale-auth-key = {};
    };
  };
}
