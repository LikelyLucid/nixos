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

  # Write the decrypted Ollama key to pi's auth.json at boot
  systemd.services.ollama-pi-auth = {
    description = "Write Ollama API key to pi auth.json";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeScriptBin "write-ollama-auth" ''
        #!${pkgs.runtimeShell}
        KEY=$(cat ${secretsDir})
        printf '{"ollama-cloud":{"type":"api_key","key":"%s"}}\n' "$KEY" > /home/lucid/.pi/agent/auth.json
        chmod 600 /home/lucid/.pi/agent/auth.json
      ''}/bin/write-ollama-auth";
      PrivateTmp = true;
    };
  };
}
