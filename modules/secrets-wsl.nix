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

  # GitHub git auth: gh CLI already holds the credential in ~/.config/gh
  # (persists across rebuilds). One system gitconfig line wires gh as the
  # credential helper, so `git push` works with no manual config per repo.
  environment.etc.gitconfig.text = ''
    [credential "https://github.com"]
      helper = !gh auth git-credential
  '';

  # Also write auth.json so pi works in non-login shells too
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
        chown lucid:users /home/lucid/.pi/agent/auth.json
      ''}/bin/write-ollama-auth";
      PrivateTmp = true;
    };
  };
}
