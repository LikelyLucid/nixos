{ config, lib, pkgs, ... }:
let
  secretsDir = config.sops.secrets.ollama-api-key.path;
in {
  sops = {
    age.keyFile = "/home/lucid/.secrets/age.agekey";
    defaultSopsFile = ../secrets/wsl-secrets.yaml;
    secrets = {
      ollama-api-key = { };
    };
  };

  # Export OLLAMA_API_KEY from the decrypted sops secret for all login shells
  environment.etc."profile.d/ollama-api-key.sh".text = ''
    export OLLAMA_API_KEY="$(cat ${secretsDir})"
  '';
}
