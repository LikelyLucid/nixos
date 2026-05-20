{ config, lib, pkgs, ... }:
let
  secretsDir = config.sops.secrets.ollama-api-key.path;
in {
  sops = {
    age.keyFile = "/home/lucid/.secrets/age.agekey";
    defaultSopsFile = ../secrets/wsl-secrets.yaml;
    secrets = {
      ollama-api-key = {
        owner = "lucid";
      };
    };
  };

  # Export OLLAMA_API_KEY from the decrypted sops secret in all shells
  environment.extraInit = ''
    export OLLAMA_API_KEY="$(cat ${secretsDir})"
  '';
}
