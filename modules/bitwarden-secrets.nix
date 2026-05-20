{ config, lib, pkgs, ... }:
let
  cfg = config.bitwarden;
  secretsDir = "/run/bitwarden-secrets";

  secretPaths = lib.mapAttrs' (name: _:
    lib.nameValuePair name "${secretsDir}/${name}"
  ) cfg.secrets;

  # Build the secrets loop at Nix build time
  secretFetches = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: secret: ''
    echo "  -> ${name}"
    bw get field ${secret.field} --itemid "${secret.item}" --session "$BW_SESSION" > /tmp/.bw-${name} 2>/dev/null \
    || bw get ${secret.field} "${secret.item}" --session "$BW_SESSION" > /tmp/.bw-${name} 2>/dev/null \
    || { echo "  Failed to fetch '${name}'" >&2; exit 1; }
    mv /tmp/.bw-${name} "$SECRETS_DIR/${name}"
    chmod 0400 "$SECRETS_DIR/${name}"
  '') cfg.secrets);

  fetchScript = pkgs.writeScriptBin "bitwarden-fetch" ''
    #!${pkgs.runtimeShell}
    set -e

    SERVER="${cfg.serverUrl}"
    EMAIL="${cfg.auth.email}"
    SESSION_FILE="${cfg.auth.sessionFile}"
    CLIENT_ID_FILE="${cfg.auth.clientIdFile}"
    CLIENT_SECRET_FILE="${cfg.auth.clientSecretFile}"
    MASTER_PASS_FILE="${cfg.auth.masterPasswordFile}"
    SECRETS_DIR="${secretsDir}"

    echo "[bitwarden] Server: $SERVER"

    if [ -n "$SERVER" ]; then
      bw config server "$SERVER" 2>/dev/null || true
    fi

    # 1. Try to unlock first (idempotent)
    if [ -f "$MASTER_PASS_FILE" ]; then
      echo "[bitwarden] Unlocking vault..."
      BW_SESSION=$(bw unlock --passwordfile "$MASTER_PASS_FILE" --raw 2>/dev/null) || true
    elif [ -f "$SESSION_FILE" ]; then
      echo "[bitwarden] Using existing session file..."
      BW_SESSION=$(cat "$SESSION_FILE" 2>/dev/null || true)
    fi

    # 2. If no session, try email+password login
    if [ -z "$BW_SESSION" ]; then
      if [ -n "$EMAIL" ] && [ -f "$MASTER_PASS_FILE" ]; then
        echo "[bitwarden] Logging in with email..."
        bw logout 2>/dev/null || true
        BW_PASS=$(cat "$MASTER_PASS_FILE")
        bw login "$EMAIL" "$BW_PASS" 2>/dev/null || true
        BW_SESSION=$(bw unlock --passwordfile "$MASTER_PASS_FILE" --raw 2>/dev/null) || true
      # 3. Fall back to API key login
      elif [ -f "$CLIENT_ID_FILE" ] && [ -f "$CLIENT_SECRET_FILE" ]; then
        echo "[bitwarden] Logging in with API key..."
        export BW_CLIENTID=$(cat "$CLIENT_ID_FILE")
        export BW_CLIENTSECRET=$(cat "$CLIENT_SECRET_FILE")
        bw logout 2>/dev/null || true
        bw login --apikey 2>/dev/null || true
        if [ -f "$MASTER_PASS_FILE" ]; then
          BW_SESSION=$(bw unlock --passwordfile "$MASTER_PASS_FILE" --raw 2>/dev/null) || true
        fi
      fi
    fi

    # 4. Still no session? Exit gracefully
    if [ -z "$BW_SESSION" ]; then
      echo "[bitwarden] WARNING: Could not unlock vault" >&2
      echo "[bitwarden]   Provide: auth.email + auth.masterPasswordFile" >&2
      echo "[bitwarden]   Or: API key files + master password file" >&2
      echo "[bitwarden] Skipping secret fetch."
      exit 0
    fi

    printf '%s\n' "$BW_SESSION" > "$SESSION_FILE"

    # 5. Fetch secrets
    ${secretFetches}

    echo "[bitwarden] Secrets written to $SECRETS_DIR"
  '';
in {
  options.bitwarden = {
    enable = lib.mkEnableOption "Bitwarden CLI secret management";

    serverUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "https://vaultwarden.likelylucid.com";
    };

    auth.email = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "user@example.com";
    };

    auth.sessionFile = lib.mkOption {
      type = lib.types.str;
      default = "/home/lucid/.config/bw-session";
    };

    auth.clientIdFile = lib.mkOption {
      type = lib.types.str;
      default = "/home/lucid/.config/bw-client-id";
    };

    auth.clientSecretFile = lib.mkOption {
      type = lib.types.str;
      default = "/home/lucid/.config/bw-client-secret";
    };

    auth.masterPasswordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/home/lucid/.config/bw-master-pass";
    };

    secrets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          item = lib.mkOption { type = lib.types.str; };
          field = lib.mkOption { type = lib.types.str; default = "password"; };
        };
      });
      default = { };
    };

    secretPaths = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      internal = true;
      readOnly = true;
    };
  };

  config = lib.mkIf cfg.enable {
    bitwarden.secretPaths = secretPaths;
    environment.systemPackages = [ pkgs.bitwarden-cli ];
    systemd.tmpfiles.rules = [ "d ${secretsDir} 0700 root root -" ];

    systemd.services.bitwarden-secrets = {
      description = "Fetch secrets from Bitwarden at boot";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${fetchScript}/bin/bitwarden-fetch";
        PrivateTmp = true;
        ReadWritePaths = [ secretsDir ];
        ProtectSystem = "strict";
      };
    };
  };
}
