#!/usr/bin/env python3
"""Carry runtime-only Hermes environment values across Nix activations."""

from __future__ import annotations

import os
import re
import stat
import sys
import tempfile
from pathlib import Path

_ASSIGNMENT = re.compile(rb"^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=")
_KEY = re.compile(rb"^[A-Za-z_][A-Za-z0-9_]*$")


def _keys(contents: bytes) -> set[bytes]:
    keys: set[bytes] = set()
    for line in contents.splitlines():
        match = _ASSIGNMENT.match(line)
        if match is not None:
            keys.add(match.group(1))
    return keys


def merge_environment(
    generated: bytes, previous: bytes, previously_managed: set[bytes] | None = None
) -> bytes:
    """Keep runtime-only keys; current and prior Nix-managed keys remain authoritative."""
    generated_keys = _keys(generated)
    managed_keys = generated_keys | (previously_managed or set())
    runtime_lines = [
        line
        for line in previous.splitlines(keepends=True)
        if (match := _ASSIGNMENT.match(line)) is not None and match.group(1) not in managed_keys
    ]
    if not runtime_lines:
        return generated

    merged = generated
    if merged and not merged.endswith((b"\n", b"\r")):
        merged += b"\n"
    for line in runtime_lines:
        merged += line
        if not line.endswith((b"\n", b"\r")):
            merged += b"\n"
    return merged


def _atomic_write(path: Path, contents: bytes, uid: int, gid: int, mode: int) -> None:
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.merge-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as temporary_file:
            temporary_file.write(contents)
            temporary_file.flush()
            os.fsync(temporary_file.fileno())
            os.fchown(temporary_file.fileno(), uid, gid)
            os.fchmod(temporary_file.fileno(), mode)
        os.replace(temporary_name, path)
    finally:
        if os.path.exists(temporary_name):
            os.unlink(temporary_name)


def merge_file(destination: Path, previous_file: Path, managed_keys_file: Path) -> None:
    generated = destination.read_bytes()
    previous = previous_file.read_bytes() if previous_file.exists() else b""
    old_managed = (
        {line for line in managed_keys_file.read_bytes().splitlines() if _KEY.fullmatch(line)}
        if managed_keys_file.exists()
        else set()
    )
    merged = merge_environment(generated, previous, old_managed)

    destination_metadata = destination.stat()
    destination_mode = stat.S_IMODE(destination_metadata.st_mode)
    if merged != generated:
        _atomic_write(
            destination,
            merged,
            destination_metadata.st_uid,
            destination_metadata.st_gid,
            destination_mode,
        )

    managed_contents = b"".join(key + b"\n" for key in sorted(_keys(generated)))
    if managed_keys_file.exists():
        manifest_metadata = managed_keys_file.stat()
        manifest_uid = manifest_metadata.st_uid
        manifest_gid = manifest_metadata.st_gid
        manifest_mode = stat.S_IMODE(manifest_metadata.st_mode)
    else:
        manifest_uid = destination_metadata.st_uid
        manifest_gid = destination_metadata.st_gid
        manifest_mode = destination_mode
    if not managed_keys_file.exists() or managed_keys_file.read_bytes() != managed_contents:
        _atomic_write(managed_keys_file, managed_contents, manifest_uid, manifest_gid, manifest_mode)


def main() -> int:
    if len(sys.argv) != 4:
        print(f"usage: {sys.argv[0]} DESTINATION PREVIOUS MANAGED_KEYS", file=sys.stderr)
        return 2
    merge_file(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
