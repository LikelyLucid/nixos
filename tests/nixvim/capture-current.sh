#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
output=${1:-"$repo_root/tests/nixvim/baseline/lazyvim.json"}
output_dir=$(dirname -- "$output")

mkdir -p "$output_dir"
NVIM_PARITY_OUTPUT="$output.tmp" \
  nvim --headless "+luafile $repo_root/tests/nixvim/dump-runtime.lua" \
  >"$output_dir/lazyvim.stdout" \
  2>"$output_dir/lazyvim.stderr"
jq . "$output.tmp" >"$output"
rm -f "$output.tmp"

jq '{
  version,
  colorscheme,
  pluginCount: (.plugins | length),
  keymapCount: (.keymaps | length),
  commandCount: (.commands | length),
  parserCount: (.parsers | length)
}' "$output"
