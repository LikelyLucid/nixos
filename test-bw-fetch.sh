#!/usr/bin/env bash
set -e

SESSION_FILE="/home/lucid/.config/bw-session-final"
BW_SESSION="$(cat "$SESSION_FILE")"

echo "Session: ${#SESSION_FILE} bytes"

# Delete duplicate Ollama items (keep the newer one fe9f43b1)
echo "=== Cleaning duplicates ==="
bw delete item dad9aff8-bac2-4ace-855c-2c450c381800 --session "$BW_SESSION" 2>/dev/null
echo "Deleted Ollama dup: $?"

# Find and delete duplicate Tailscale items
echo "=== Finding Tailscale items ==="
bw list items --session "$BW_SESSION" 2>/dev/null | python3 -c "
import sys,json
data = json.load(sys.stdin)
ts_items = [i for i in data if 'Tailscale' in i['name']]
# Keep first, delete rest
for i in ts_items[1:]:
    print(i['id'])
" >/tmp/ts-dups.txt 2>/dev/null
while read id; do
	bw delete item "$id" --session "$BW_SESSION" 2>/dev/null || true
	echo "Deleted Tailscale dup: $id"
done </tmp/ts-dups.txt

# Now fetch single results
echo ""
echo "=== Fetch Ollama API Key ==="
OLLAMA_KEY=$(bw get password "Ollama API Key" --session "$BW_SESSION" 2>/dev/null)
echo "$OLLAMA_KEY"

echo ""
echo "=== Fetch Tailscale Auth Key ==="
TAILSCALE_KEY=$(bw get password "Tailscale Auth Key" --session "$BW_SESSION" 2>/dev/null)
echo "$TAILSCALE_KEY"

echo ""
echo "=== Write to pi auth.json ==="
printf '{"ollama-cloud":{"type":"api_key","key":"%s"}}\n' "$OLLAMA_KEY" >/home/lucid/.pi/agent/auth.json
cat /home/lucid/.pi/agent/auth.json
