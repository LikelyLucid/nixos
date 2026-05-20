#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# Bitwarden (Vaultwarden) Setup — API Key + Master Password
#
# ONE-TIME interactive setup. After this, secrets auto-fetch at EVERY BOOT.
# You only need your master password once during this setup.
# ═══════════════════════════════════════════════════════════════════════════════

set -e

VAULTWARDEN_URL="https://vaultwarden.likelylucid.com"
CLIENT_ID_FILE="$HOME/.config/bw-client-id"
CLIENT_SECRET_FILE="$HOME/.config/bw-client-secret"
MASTER_PASS_FILE="$HOME/.config/bw-master-pass"
SESSION_FILE="$HOME/.config/bw-session"

Info="\e[36m"; Success="\e[32m"; Warning="\e[33m"; Error="\e[31m"; Reset="\e[0m"

echo -e "${Info}╔══════════════════════════════════════════════════════╗${Reset}"
echo -e "${Info}║  Vaultwarden Setup — One-Time Interactive           ║${Reset}"
echo -e "${Info}║  Server: ${VAULTWARDEN_URL}  ║${Reset}"
echo -e "${Info}╚══════════════════════════════════════════════════════╝${Reset}"
echo ""
echo -e "${Warning}After this, secrets auto-fetch at every boot.${Reset}"
echo ""

# ─── Ensure bw is available ─────────────────────────────────────────────────
if ! command -v bw &>/dev/null; then
    echo -e "${Info}◆ Bitwarden CLI not found. Launching nix shell...${Reset}"
    exec nix shell nixpkgs#bitwarden-cli --command bash "$0"
fi

# ─── Check if already fully configured ──────────────────────────────────────
if [ -f "$CLIENT_ID_FILE" ] && [ -f "$CLIENT_SECRET_FILE" ] && [ -f "$MASTER_PASS_FILE" ]; then
    echo -e "${Success}✓ Already configured. Testing...${Reset}"
    export BW_CLIENTID="$(cat $CLIENT_ID_FILE)"
    export BW_CLIENTSECRET="$(cat $CLIENT_SECRET_FILE)"
    if bw login --apikey 2>/dev/null; then
        SESSION=$(bw unlock --passwordfile "$MASTER_PASS_FILE" --raw 2>/dev/null)
        if [ -n "$SESSION" ]; then
            echo "$SESSION" > "$SESSION_FILE"
            echo -e "${Success}✓ Session valid. Secrets will auto-fetch at boot.${Reset}"
            exit 0
        fi
    fi
    echo -e "${Warning}⚠ Setup needs re-run.${Reset}"
fi

# ─── Configure server ───────────────────────────────────────────────────────
echo -e "${Info}◆ Configuring server: ${VAULTWARDEN_URL}${Reset}"
bw config server ${VAULTWARDEN_URL}
echo -e "${Success}  Server configured${Reset}"
echo ""

# ─── STEP 1: Get API key credentials ────────────────────────────────────────
echo -e "${Info}◆ Step 1: Enter your Vaultwarden API credentials${Reset}"
echo -e "${Warning}  (From the Vaultwarden web UI: Settings → Security → Keys → API Key)${Reset}"
echo ""

read -p "  client_id (e.g. user.xxxx-xxxx-...): " BW_CLIENT_ID
read -s -p "  client_secret: " BW_CLIENT_SECRET
echo ""

if [ -z "$BW_CLIENT_ID" ] || [ -z "$BW_CLIENT_SECRET" ]; then
    echo -e "${Error}  Both values are required.${Reset}"
    exit 1
fi

# ─── Save API credentials ───────────────────────────────────────────────────
mkdir -p "$HOME/.config"
echo "$BW_CLIENT_ID" > "$CLIENT_ID_FILE"
echo "$BW_CLIENT_SECRET" > "$CLIENT_SECRET_FILE"
chmod 600 "$CLIENT_ID_FILE" "$CLIENT_SECRET_FILE"
echo -e "${Success}✓ API credentials saved${Reset}"
echo ""

# ─── STEP 2: Get master password for decryption ─────────────────────────────
echo -e "${Info}◆ Step 2: Enter your Bitwarden MASTER PASSWORD${Reset}"
echo -e "${Warning}  (This is your VAULT DECRYPTION KEY — needed to read secrets at boot.${Reset}"
echo -e "${Warning}   Stored locally in a file with restricted permissions.)${Reset}"
echo ""

read -s -p "  Master password (one-time, stored for boot): " BW_MASTER_PASS
echo ""
read -s -p "  Confirm master password: " BW_MASTER_PASS_CONFIRM
echo ""

if [ -z "$BW_MASTER_PASS" ]; then
    echo -e "${Error}  Master password is required.${Reset}"
    exit 1
fi

if [ "$BW_MASTER_PASS" != "$BW_MASTER_PASS_CONFIRM" ]; then
    echo -e "${Error}  Passwords don't match.${Reset}"
    exit 1
fi

echo "$BW_MASTER_PASS" > "$MASTER_PASS_FILE"
chmod 400 "$MASTER_PASS_FILE"
echo -e "${Success}✓ Master password saved to $MASTER_PASS_FILE (chmod 400)${Reset}"
echo ""

# ─── STEP 3: Login with API key ──────────────────────────────────────────────
echo -e "${Info}◆ Step 3: Logging in with API key...${Reset}"

bw logout 2>/dev/null || true
export BW_CLIENTID="$BW_CLIENT_ID"
export BW_CLIENTSECRET="$BW_CLIENT_SECRET"
bw login --apikey 2>/dev/null
echo -e "${Success}✓ Logged in successfully${Reset}"
echo ""

# ─── STEP 4: Unlock and save session ────────────────────────────────────────
echo -e "${Info}◆ Step 4: Unlocking vault and creating session...${Reset}"

SESSION=$(bw unlock --passwordfile "$MASTER_PASS_FILE" --raw 2>/dev/null)

if [ -z "$SESSION" ]; then
    echo -e "${Error}  Unlock failed. Wrong master password?${Reset}"
    exit 1
fi

echo "$SESSION" > "$SESSION_FILE"
chmod 600 "$SESSION_FILE"
echo -e "${Success}✓ Session created and saved${Reset}"
echo ""

# ─── STEP 5: Test by fetching a secret ──────────────────────────────────────
echo -e "${Info}◆ Step 5: Testing secret fetch...${Reset}"

# Try fetching the Tailscale key
SECRET=$(bw get password "Tailscale Auth Key" --session "$SESSION" 2>/dev/null || echo "")
if [ -n "$SECRET" ]; then
    echo -e "${Success}✓ Successfully fetched 'Tailscale Auth Key'${Reset}"
else
    echo -e "${Warning}⚠ Could not fetch 'Tailscale Auth Key'.${Reset}"
    echo -e "${Warning}  Make sure this item exists in your vault.${Reset}"
fi
echo ""

# ─── Done ────────────────────────────────────────────────────────────────────
echo -e "${Success}╔══════════════════════════════════════════════════════╗${Reset}"
echo -e "${Success}║  SETUP COMPLETE!                                    ║${Reset}"
echo -e "${Success}╚══════════════════════════════════════════════════════╝${Reset}"
echo ""
echo -e "${Info}What was set up:${Reset}"
echo "  ✅ API key saved to ~/.config/bw-client-{id,secret}"
echo "  ✅ Master password saved to $MASTER_PASS_FILE (chmod 400)"
echo "  ✅ Logged in with bw (encrypted vault cached locally)"
echo "  ✅ Session created and tested"
echo ""
echo -e "${Info}What happens at every boot:${Reset}"
echo "  1. bw login --apikey (auto, uses saved credentials)"
echo "  2. bw unlock --passwordfile (auto, reads saved password)"
echo "  3. Secrets fetched to /run/bitwarden-secrets/"
echo ""
echo -e "${Info}Rebuild and test:${Reset}"
echo "  sudo nixos-rebuild switch --flake ~/nixos#wsl"
echo "  sudo systemctl start bitwarden-secrets"
echo "  sudo cat /run/bitwarden-secrets/tailscale-auth-key"
echo ""
echo -e "${Success}Done!${Reset}"
