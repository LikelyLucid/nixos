{ config, lib, pkgs, ... }:
let
  cfg = config.bitwarden;
  secretsDir = "/run/bitwarden-secrets";

  # Compute secret paths for other modules
  secretPaths = lib.mapAttrs' (name: _:
    lib.nameValuePair name "${secretsDir}/${name}"
  ) cfg.secrets;

  # ─── Build the fetch script ────────────────────────────────────────────────
  # We use pkgs.writeScriptBin to avoid Nix string interpolation issues with
  # bash variables. The script receives all parameters as CLI args from the
  # systemd service.

  fetchScript = pkgs.writeScriptBin "bitwarden-fetch" (''
    #!${pkgs.runtimeShell}
    set -e

    SERVER="${cfg.serverUrl}"
    METHOD="${cfg.auth.method}"
    SESSION_FILE="${cfg.auth.sessionFile}"
    CLIENT_ID_FILE="${cfg.auth.clientIdFile}"
    CLIENT_SECRET_FILE="${cfg.auth.clientSecretFile}"
    SECRETS_DIR="${secretsDir}"

    # Configure server
    if [ -n "$SERVER" ]; then
      echo "[bitwarden] Server: $SERVER"
      export BW_SERVER="$SERVER"
      bw config server "$SERVER" 2>/dev/null || true
    else
      echo "[bitwarden] Server: bitwarden.com (official)"
    fi

    # Authenticate
    if [ "$METHOD" = "api-key" ]; then
      echo "[bitwarden] Logging in with API key..."
      BW_CLIENTID="$(cat "$CLIENT_ID_FILE")"
      BW_CLIENTSECRET="$(cat "$CLIENT_SECRET_FILE")"
      export BW_SESSION="$(printf '%s\n%s\n' "$BW_CLIENTID" "$BW_CLIENTSECRET" | bw login --apikey --raw 2>/dev/null)"
      if [ -z "$BW_SESSION" ]; then
        echo "[bitwarden] WARNING: Login failed - check API credentials" >&2
        echo "[bitwarden] Skipping secret fetch."
        exit 0
      fi
    else
      echo "[bitwarden] Using session file: $SESSION_FILE"
      if [ ! -f "$SESSION_FILE" ]; then
        echo "[bitwarden] Session file not found at $SESSION_FILE" >&2
        echo "  Run: bw unlock --raw > $SESSION_FILE" >&2
        exit 1
      fi
    fi
  '' + (lib.concatStringsSep "\n" (lib.mapAttrsToList (name: secret: ''
    echo "  → ${name}"
    bw get field ${secret.field} --itemid "${secret.item}" --session "$(cat "$SESSION_FILE")" > /tmp/.bw-${name} 2>/dev/null || bw get ${secret.field} "${secret.item}" --session "$(cat "$SESSION_FILE")" > /tmp/.bw-${name} 2>/dev/null || { echo "  Failed to fetch '${name}'" >&2; exit 1; }
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
      method = lib.mkOption {
        type = lib.types.enum [ "session-file" "api-key" ];
        default = "session-file";
        description = "Authentication method for Bitwarden CLI.";
      };

      sessionFile = lib.mkOption {
        type = lib.types.str;
        default = "/home/lucid/.config/bw-session";
        description = "Path to Bitwarden session key file (for session-file method)";
      };

      clientIdFile = lib.mkOption {
        type = lib.types.str;
        default = "/home/lucid/.config/bw-client-id";
        description = "Path to Bitwarden API client_id file (for api-key method)";
      };

      clientSecretFile = lib.mkOption {
        type = lib.types.str;
        default = "/home/lucid/.config/bw-client-secret";
        description = "Path to Bitwarden API client_secret file (for api-key method)";
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
        ProtectSystem = "strict";
        ReadWritePaths = [ secretsDir ];
      };
    };

    # Expose secrets via /etc for easy reference
    environment.etc = lib.mapAttrs' (name: _:
      lib.nameValuePair "bitwarden-secrets/${name}" {
        source = "${secretsDir}/${name}";
        mode = "0400";
      }
    ) cfg.secrets;
  };
}
