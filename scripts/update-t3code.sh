#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
package_file="$repo_root/modules/dev/t3code.nix"
release_json="$(curl -fsSL 'https://api.github.com/repos/pingdotgg/t3code/releases?per_page=100')"
release_info="$(python3 -c '
import json
import sys

releases = json.load(sys.stdin)
release = next(item for item in releases if item["prerelease"])
version = release["tag_name"].removeprefix("v")
asset = next(
    item for item in release["assets"]
    if item["name"] == f"T3-Code-{version}-x86_64.AppImage"
)
print(version)
print(asset["browser_download_url"])
' <<< "$release_json")"
version="$(sed -n '1p' <<< "$release_info")"
url="$(sed -n '2p' <<< "$release_info")"
hash_base32="$(nix-prefetch-url --type sha256 "$url" | tail -n 2 | head -n 1)"
hash="$(nix hash convert --hash-algo sha256 --to sri "$hash_base32")"

VERSION="$version" HASH="$hash" python3 - "$package_file" <<'PY'
import os
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
source = path.read_text()
source, version_count = re.subn(
    r'(?m)^(\s*version = ")[^"]+(";)$',
    rf'\g<1>{os.environ["VERSION"]}\g<2>',
    source,
)
source, hash_count = re.subn(
    r'(?m)^(\s*hash = ")[^"]+(";)$',
    rf'\g<1>{os.environ["HASH"]}\g<2>',
    source,
)
if version_count != 1 or hash_count != 1:
    raise SystemExit("Expected exactly one version and hash in t3code.nix")
path.write_text(source)
PY

printf 'Updated T3 Code to %s (%s)\n' "$version" "$hash"
