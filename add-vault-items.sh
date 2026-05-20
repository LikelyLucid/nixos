#!/usr/bin/env bash
set -e

echo "=== Getting fresh session ==="
bw unlock --passwordfile /home/lucid/.config/bw-master-pass --raw >/tmp/bw-sess-create 2>/dev/null

echo "=== Creating Tailscale Auth Key ==="
bw create item --session "$(cat /tmp/bw-sess-create)" \
	"eyJ0eXBlIjoxLCJuYW1lIjoiVGFpbHNjYWxlIEF1dGggS2V5IiwibG9naW4iOnsicGFzc3dvcmQiOiJ0c2tleS1hcGkta0pyQ0ZmTTNENDExQ05UUkwtcUNaZ2FwNU0yTlYzRHRueEx5bnpNVkN3THdDWnB0VkNaIn19" 2>&1
echo "Exit: $?"

echo "=== Creating Ollama API Key ==="
bw create item --session "$(cat /tmp/bw-sess-create)" \
	"eyJ0eXBlIjoxLCJuYW1lIjoiT2xsYW1hIEFQSSBLZXkiLCJsb2dpbiI6eyJwYXNzd29yZCI6IlJxRzY5NDVydWlVUGY1T3BhbUFCMmZRd2ZUamx6MiJ9fQ==" 2>&1
echo "Exit: $?"

echo "=== Verify ==="
bw list items --session "$(cat /tmp/bw-sess-create)" 2>/dev/null | python3 -c "
import sys,json
data = json.load(sys.stdin)
for item in data:
    if 'Tailscale' in item['name'] or 'Ollama' in item['name']:
        print(f\"  {item['name']}: {item['login']['password']}\")
" 2>/dev/null
