{ config, lib, pkgs, ... }:
let
  cfg = config.bitwarden;
  secretsDir = "/run/bitwarden-secrets";

  # Compute secret paths for other modules
  secretPaths = lib.mapAttrs' (name: _:
    lib.nameValuePair name "${secretsDir}/${name}"
  ) cfg.secrets;

  fetchScript = pkgs.writeScriptBin "bitwarden-fetch" (''
    #!${pkgs.runtimeShell}
    set -e

    SERVER="${cfg.serverUrl}"
    SESSION_FILE="${cfg.auth.sessionFile}"
    CLIENT_ID_FILE="${cfg.auth.clientIdFile}"
    CLIENT_SECRET_FILE="${cfg.auth.clientSecretFile}"
    MASTER_PASS_FILE="${cfg.auth.masterPasswordFile}"
    SECRETS_DIR="${secretsDir}"

    echo "[bitwarden] Server: $SERVER"

    # 1. Log in with API key (idempotent - bw skips if already logged in)
    export BW_CLIENTID="$(cat "$CLIENT_ID_FILE" 2>/dev/null || true)"
    export BW_CLIENTSECRET="$(cat "$CLIENT_SECRET_FILE" 2>/dev/null || true)"

    if [ -z "$BW_CLIENTID" ] || [ -z "$BW_CLIENTSECRET" ]; then
      echo "[bitwarden] WARNING: API credentials not found" >&2
      echo "[bitwarden]   Place client_id in: $CLIENT_ID_FILE" >&2
      echo "[bitwarden]   Place client_secret in: $CLIENT_SECRET_FILE" >&2
      echo "[bitwarden] Skipping secret fetch."
      exit 0
    fi

    # Configure server URL if set
    if [ -n "$SERVER" ]; then
      bw config server "$SERVER" 2>/dev/null || true
    fi

    # Login (quietly - bw stores encrypted vault locally)
    BW_SESSION="$(bw login --apikey --raw 2>/dev/null)" || true

    # 2. Unlock with master password file (non-interactive via --passwordfile)
    if [ -f "$MASTER_PASS_FILE" ]; then
      echo "[bitwarden] Unlocking vault..."
      BW_SESSION="$(bw unlock --passwordfile "$MASTER_PASS_FILE" --raw 2>/dev/null)"
    elif [ -f "$SESSION_FILE" ]; then
      echo "[bitwarden] Using existing session file..."
      BW_SESSION="$(cat "$SESSION_FILE")"
    fi

    if [ -z "$BW_SESSION" ]; then
      echo "[bitwarden] WARNING: Could not unlock vault" >&2
      echo "[bitwarden]   Run: bw unlock --raw > $SESSION_FILE" >&2
      echo "[bitwarden]   Or create: $MASTER_PASS_FILE with your master password" >&2
      echo "[bitwarden] Skipping secret fetch."
      exit 0
    fi

    # Save session for later runs
    printf '%s\n' "$BW_SESSION" > "$SESSION_FILE"

    # 3. Fetch each secret
  '' + (lib.concatStringsSep "\n" (lib.mapAttrsToList (name: secret: ''
    echo "  → ${name}"
    bw get field ${secret.field} --itemid "${secret.item}" --session "$BW_SESSION" > /tmp/.bw-${name} 2>/dev/null \
    || bw get ${secret.field} "${secret.item}" --session "$BW_SESSION" > /tmp/.bw-${name} 2>/dev/null \
    || { echo "  Failed to fetch '${name}'" >&2; exit 1; }
    mv /tmp/.bw-${name} "$SECRETS_DIR/${name}"
    chmod 0400 "$SECRETS_DIR/${name}"
  '') cfg.secrets)) + ''
    echo "[bitwarden] Secrets written to $SECRETS_DIR"
  '');
in {
  ############################################
  # OPTIONS
  ############################################
  options.bitwarden = {
    enable = lib.mkEnableOption "Bitwarden CLI secret management";

    serverUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Custom Bitwarden server URL for self-hosted instances (e.g. Vaultwarden).
        If null, uses the official Bitwarden server.
      '';
      example = "https://vaultwarden.likelylucid.com";
    };

    auth = {
      sessionFile = lib.mkOption {
        type = lib.types.str;
        default = "/home/lucid/.config/bw-session";
        description = "Path to Bitwarden session key file";
      };

      clientIdFile = lib.mkOption {
        type = lib.types.str;
        default = "/home/lucid/.config/bw-client-id";
        description = "Path to Bitwarden API client_id file";
      };

      clientSecretFile = lib.mkOption {
        type = lib.types.str;
        default = "/home/lucid/.config/bw-client-secret";
        description = "Path to Bitwarden API client_secret file";
      };

      masterPasswordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Path to a file containing the Bitwarden master password.
          Used with `bw unlock --passwordfile` for non-interactive unlock.
          This file should have restricted permissions (chmod 400).
        '';
        example = "/home/lucid/.config/bw-master-pass";
      };
    };

    secrets = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          item = lib.mkOption {
            type = lib.types.str;
            description = "Bitwarden item ID or name to fetch";
            example = "c6e7b2e1-7a3d-4f8b-9c0d-1e2f3a4b5c6d";
          };
          field = lib.mkOption {
            type = lib.types.str;
            default = "password";
            description = "Field to extract (password, username, notes, or custom field)";
          };
        };
      });
      default = { };
      description = "Secrets to fetch from Bitwarden at boot";
      example = {
        tailscale-auth-key = {
          item = "Tailscale Auth Key";
          field = "password";
        };
      };
    };

    secretPaths = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      internal = true;
      readOnly = true;
      description = "Computed paths to fetched Bitwarden secrets";
    };
  };

  ############################################
  # CONFIG
  ############################################
  config = lib.mkIf cfg.enable {
    # Expose computed secret paths
    bitwarden.secretPaths = secretPaths;

    # Install Bitwarden CLI
    environment.systemPackages = [ pkgs.bitwarden-cli ];

    # Create the secrets directory at boot
    systemd.tmpfiles.rules = [
      "d ${secretsDir} 0700 root root -"
    ];

    # Systemd oneshot service to fetch secrets at boot
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
        ReadWritePaths = [
          secretsDir
          "/home/lucid/.config"
        ];
        # Access API credentials and master password
        ProtectSystem = "strict";
        ProtectHome = "read-only";
      };
    };
  };
}
