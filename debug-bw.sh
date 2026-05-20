#!/usr/bin/env bash
MASTER_PASS_FILE=/home/lucid/.config/bw-master-pass
SESSION_FILE=/home/lucid/.config/bw-session

export HOME=/home/lucid

get_session() {
	rm -f "${SESSION_FILE}.tmp"
	if [ -f "$MASTER_PASS_FILE" ]; then
		echo "  (unlocking...)"
		bw unlock --passwordfile "$MASTER_PASS_FILE" --raw >"${SESSION_FILE}.tmp" 2>&1
		local rc=$?
		echo "  exit: $rc"
		echo "  bytes: $(wc -c <"${SESSION_FILE}.tmp")"
	fi
	local result="$(cat "${SESSION_FILE}.tmp" 2>/dev/null || true)"
	rm -f "${SESSION_FILE}.tmp" 2>/dev/null || true
	echo "$result"
}

echo "=== get_session result ==="
SESSION="$(get_session)"
echo "Session length: ${#SESSION}"
if [ -n "$SESSION" ]; then
	echo "Session OK: ${SESSION:0:20}..."
fi
