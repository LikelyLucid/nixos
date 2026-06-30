{ config, lib, pkgs, ... }:
let
  secretsDir = config.sops.secrets.ollama-api-key.path;
  githubTokenFile = config.sops.secrets.github-token.path;
  # Git credential helper that reads the decrypted token from /run/secrets.
  git-credential-sops = pkgs.writeShellScriptBin "git-credential-sops" ''
    case "$1" in
      get)
        printf 'username=LikelyLucid\n'
        printf 'password=%s\n' "$(cat ${githubTokenFile})"
        printf '\n'
        ;;
      # store/erase: no-op, the token lives in /run/secrets
    esac
  '';
in {
  sops = {
    age.keyFile = "/home/lucid/.secrets/age.agekey";
    defaultSopsFile = ../secrets/wsl-secrets.yaml;
    secrets = {
      ollama-api-key = {
        owner = "lucid";
      };
      github-token = {
        owner = "lucid";
      };
    };
  };

  # Export OLLAMA_API_KEY from the decrypted sops secret in all shells
  environment.extraInit = ''
    export OLLAMA_API_KEY="$(cat ${secretsDir})"
  '';

  # Git credential helper backed by the sops github-token secret.
  # System-wide so all repos on this host authenticate to GitHub without
  # a manual `gh auth login` after each rebuild.
  environment.systemPackages = [ git-credential-sops ];
  environment.etc.gitconfig.text = ''
    [credential "https://github.com"]
      helper = !git-credential-sops
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
