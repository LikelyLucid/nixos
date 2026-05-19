{ isWsl ? false, lib, ... }:
lib.mkIf (!isWsl) {
  sops = {
    age.keyFile = "/home/lucid/.secrets/age.agekey";
    defaultSopsFile = ../secrets/secrets.yaml;
    secrets = {
      tailscale-auth-key = { };
    };
  };
}