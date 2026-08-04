#!/usr/bin/env bash
set -euo pipefail

root=$(git rev-parse --show-toplevel)
cd "$root"

git config --local core.hooksPath .githooks

echo "Git hooks installed from $root/.githooks"
