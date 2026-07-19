#!/usr/bin/env bash
set -euo pipefail

root=$(git rev-parse --show-toplevel)
cd "$root"

runs=${RUNS:-7}
warmup=${WARMUP:-2}
fixture_size_mib=${FIXTURE_SIZE_MIB:-128}
kernel=$(uname -r)
stamp=$(date -u +%Y%m%dT%H%M%SZ)
out_dir=${1:-tests/kernel-benchmark/results/${kernel}-${stamp}}
work_dir=$(mktemp -d "${TMPDIR:-/tmp}/kernel-benchmark.XXXXXX")
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$out_dir" "$work_dir/tree"
out_dir=$(realpath "$out_dir")

if ! command -v hyperfine >/dev/null; then
  echo "error: hyperfine is required" >&2
  exit 1
fi

ac_online=unknown
if [[ -r /sys/class/power_supply/AC/online ]]; then
  ac_online=$(</sys/class/power_supply/AC/online)
fi
if [[ $ac_online != 1 ]]; then
  echo "warning: AC power is not reported online; results may be noisy" >&2
fi

python3 - "$work_dir" "$fixture_size_mib" <<'PY'
from pathlib import Path
import json, random, sys

root = Path(sys.argv[1])
size_mib = int(sys.argv[2])
rng = random.Random(9530)
tree = root / "tree"
records = []
for i in range(3000):
    payload = {
        "id": i,
        "group": i % 37,
        "enabled": i % 5 != 0,
        "title": f"document-{i:05d}",
        "values": [rng.randrange(1_000_000) for _ in range(16)],
    }
    records.append(payload)
    path = tree / f"group-{i % 50:02d}" / f"document-{i:05d}.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload))
(root / "records.json").write_text(json.dumps(records * 8))
block = bytes(rng.randrange(256) for _ in range(1024 * 1024))
with (root / "blob.bin").open("wb") as stream:
    for _ in range(size_mib):
        stream.write(block)
PY

tar -C "$work_dir" -cf - tree blob.bin | zstd -q -T1 -3 -o "$work_dir/fixture.tar.zst"
cat >"$work_dir/web-workload.js" <<'JS'
const fs = require("fs");
const rows = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const grouped = new Map();
for (const row of rows) {
  if (!row.enabled) continue;
  const total = row.values.reduce((a, b) => a + b, 0);
  grouped.set(row.group, (grouped.get(row.group) || 0) + total);
}
const output = [...grouped].sort((a, b) => b[1] - a[1]);
if (output.length !== 37) throw new Error(`unexpected groups: ${output.length}`);
JS
cat >"$work_dir/python-workload.py" <<'PY'
import json, pathlib, sys
rows = json.loads(pathlib.Path(sys.argv[1]).read_text())
groups = {}
for row in rows:
    if row["enabled"]:
        groups[row["group"]] = groups.get(row["group"], 0) + sum(row["values"])
assert len(groups) == 37
PY

cat >"$out_dir/metadata.txt" <<EOF
utc=$stamp
kernel=$kernel
os=$(nixos-version 2>/dev/null || true)
cpu=$(sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -1)
ac_online=$ac_online
runs=$runs
warmup=$warmup
fixture_size_mib=$fixture_size_mib
scaling_driver=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || true)
scaling_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true)
EOF

printf 'Benchmarking kernel %s; output: %s\n' "$kernel" "$out_dir"
hyperfine --warmup "$warmup" --runs "$runs" --export-json "$out_dir/results.json" \
  --command-name 'app-launch/process scheduling' \
    "for i in \$(seq 1 150); do /run/current-system/sw/bin/bash -c :; done" \
  --command-name 'browser-like JavaScript' \
    "node '$work_dir/web-workload.js' '$work_dir/records.json'" \
  --command-name 'application data/Python' \
    "python3 '$work_dir/python-workload.py' '$work_dir/records.json'" \
  --command-name 'document search' \
    "grep -R -l '\"enabled\": true' '$work_dir/tree' | wc -l >/dev/null" \
  --command-name 'archive compression' \
    "tar -C '$work_dir' -cf - tree blob.bin | zstd -q -T1 -3 -c >/dev/null" \
  --command-name 'archive listing' \
    "zstd -q -d -c '$work_dir/fixture.tar.zst' | tar -tf - >/dev/null" \
  --command-name 'NixOS evaluation' \
    "nix eval --raw '.#nixosConfigurations.artsxps.config.boot.kernelPackages.kernel.version' >/dev/null"

printf '\nSaved %s and %s\n' "$out_dir/results.json" "$out_dir/metadata.txt"
