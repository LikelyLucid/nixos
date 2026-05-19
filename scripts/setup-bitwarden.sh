#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# Bitwarden (Vaultwarden) Setup — API Key Auth
# 
# This uses API key authentication which NEVER EXPIRES.
# You only need to run this script once.
# ═══════════════════════════════════════════════════════════════════════════════

set -e

VAULTWARDEN_URL="https://vaultwarden.likelylucid.com"
CLIENT_ID_FILE="$HOME/.config/bw-client-id"
CLIENT_SECRET_FILE="$HOME/.config/bw-client-secret"

Info="\e[36m"; Success="\e[32m"; Warning="\e[33m"; Error="\e[31m"; Reset="\e[0m"

echo -e "${Info}╔══════════════════════════════════════════════════════╗${Reset}"
echo -e "${Info}║  Vaultwarden API Key Setup (one-time)              ║${Reset}"
echo -e "${Info}║  Server: ${VAULTWARDEN_URL}  ║${Reset}"
echo -e "${Info}╚══════════════════════════════════════════════════════╝${Reset}"
echo ""
echo -e "${Warning}This setup is ONE-TIME. After this, secrets will auto-fetch at every boot.${Reset}"
echo ""

# ─── Ensure bw is available ─────────────────────────────────────────────────
if ! command -v bw &>/dev/null; then
    echo -e "${Info}◆ Bitwarden CLI not found. Launching nix shell...${Reset}"
    exec nix shell nixpkgs#bitwarden-cli --command bash "$0"
fi

# ─── Check if already configured ────────────────────────────────────────────
if [ -f "$CLIENT_ID_FILE" ] && [ -f "$CLIENT_SECRET_FILE" ]; then
    echo -e "${Success}✓ API credentials already exist at:${Reset}"
    echo "    $CLIENT_ID_FILE"
    echo "    $CLIENT_SECRET_FILE"
    echo ""
    echo -e "${Warning}To re-run, delete those files first:${Reset}"
    echo "    rm $CLIENT_ID_FILE $CLIENT_SECRET_FILE"
    echo ""
    read -p "Re-run anyway? (y/N): " choice
    if [ "$choice" != "y" ]; then
        echo -e "${Info}Testing current setup...${Reset}"
        export BW_CLIENTID="$(cat $CLIENT_ID_FILE)"
        export BW_CLIENTSECRET="$(cat $CLIENT_SECRET_FILE)"
        SESSION=$(bw login --apikey --raw 2>/dev/null <<< "$BW_CLIENTID"$'\n'"$BW_CLIENTSECRET" || true)
        if [ -n "$SESSION" ]; then
            echo -e "${Success}✓ API credentials work! Secrets will auto-fetch at boot.${Reset}"
            exit 0
        else
            echo -e "${Warning}⚠ Credentials exist but don't work. Re-setting up...${Reset}"
        fi
    fi
fi

# ─── Configure server ───────────────────────────────────────────────────────
echo -e "${Info}◆ Configuring server: ${VAULTWARDEN_URL}${Reset}"
bw config server ${VAULTWARDEN_URL}
echo -e "${Success}  Server configured${Reset}"
echo ""

# ─── STEP 1: Login interactively ────────────────────────────────────────────
echo -e "${Info}◆ Step 1: Log in to your Vaultwarden account${Reset}"
echo -e "${Warning}  Enter your Vaultwarden email and master password.${Reset}"

bw logout 2>/dev/null || true
bw login
echo ""

# ─── STEP 2: Get API Key from the web UI ────────────────────────────────────
echo -e "${Info}◆ Step 2: Create an API Key in the Vaultwarden web UI${Reset}"
echo ""
echo "  1. Open your Vaultwarden web interface:"
echo -e "     ${Success}${VAULTWARDEN_URL}${Reset}"
echo "  2. Go to Settings → API Key"
echo "  3. Enter your master password to reveal the keys"
echo "  4. Copy the 'client_id' and 'client_secret' values"
echo ""

bw unlock --raw > /dev/null 2>&1 || true

echo -e "${Warning}  Paste your API credentials below (they will be saved to files):${Reset}"
echo ""

read -p "  client_id:     " BW_CLIENT_ID
read -s -p "  client_secret: " BW_CLIENT_SECRET
echo ""

if [ -z "$BW_CLIENT_ID" ] || [ -z "$BW_CLIENT_SECRET" ]; then
    echo -e "${Error}  Both values are required.${Reset}"
    exit 1
fi

# ─── Save credentials ───────────────────────────────────────────────────────
mkdir -p "$HOME/.config"
echo "$BW_CLIENT_ID" > "$CLIENT_ID_FILE"
echo "$BW_CLIENT_SECRET" > "$CLIENT_SECRET_FILE"
chmod 600 "$CLIENT_ID_FILE" "$CLIENT_SECRET_FILE"
echo -e "${Success}✓ Credentials saved to ~/.config/bw-client-{id,secret}${Reset}"
echo ""

# ─── STEP 3: Test the API key ────────────────────────────────────────────────
echo -e "${Info}◆ Step 3: Testing API key...${Reset}"

bw logout 2>/dev/null || true
SESSION=$(bw login --apikey --raw 2>/dev/null <<< "$BW_CLIENT_ID"$'\n'"$BW_CLIENT_SECRET")

if [ -z "$SESSION" ]; then
    echo -e "${Error}  API key login failed. Check your credentials.${Reset}"
    exit 1
fi
echo -e "${Success}✓ API key works!${Reset}"
echo ""

# ─── STEP 4: List items for config ───────────────────────────────────────────
echo -e "${Info}◆ Step 4: Your Vaultwarden items (copy the IDs for your config):${Reset}"
echo ""

export BW_SESSION="$SESSION"
bw list items 2>/dev/null | python3 -c "
import json, sys
try:
    items = json.load(sys.stdin)
    for item in items:
        name = item.get('name', '(no name)')
        id = item.get('id', '???')
        login = item.get('login', {})
        username = login.get('username', '')
        print(f'  ID:   ${Success}{id}${Reset}')
        print(f'  Name: {name}')
        if username:
            print(f'  User: {username}')
        print()
except:
    print('  (Run: bw list items | grep \"\\\"id\\\":\")')
' || {
    echo -e "${Warning}  Could not auto-list. Run manually:${Reset}"
    echo "    bw list items"
}

# ─── Done ────────────────────────────────────────────────────────────────────
bw logout 2>/dev/null || true

echo ""
echo -e "${Success}╔══════════════════════════════════════════════════════╗${Reset}"
echo -e "${Success}║  SETUP COMPLETE!                                    ║${Reset}"
echo -e "${Success}╚══════════════════════════════════════════════════════╝${Reset}"
echo ""
echo -e "${Info}What happens now:${Reset}"
echo "  ✅ API key saved to ~/.config/bw-client-{id,secret}"
echo "  ✅ Secrets will auto-fetch at every boot via systemd"
echo "  ✅ You NEVER need to sign in again"
echo ""
echo -e "${Info}Update your config with item IDs (replace the names):${Reset}"
echo ""
echo "  nano ~/nixos/hosts/wsl/configuration.nix"
echo ""
echo "  bitwarden.secrets = {"
echo "    tailscale-auth-key = {"
echo "      item = \"<paste-item-id-here>\";   # ← Use the ID from above"
echo "      field = \"password\";"
echo "    };"
echo "  };"
echo ""
echo -e "${Success}Then rebuild:${Reset}"
echo "  sudo nixos-rebuild switch --flake ~/nixos#wsl"
echo ""
echo -e "${Info}Test secret fetching:${Reset}"
echo "  sudo systemctl start bitwarden-secrets"
echo "  sudo cat /run/bitwarden-secrets/tailscale-auth-key"
echo ""
