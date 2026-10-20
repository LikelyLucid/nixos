#!/usr/bin/env python3

import importlib.util
import stat
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("merge_hermes_env", ROOT / "scripts/merge_hermes_env.py")
assert SPEC is not None and SPEC.loader is not None
MERGER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MERGER
SPEC.loader.exec_module(MERGER)


class HermesEnvMergeTests(unittest.TestCase):
    def test_preserves_runtime_only_entries_but_keeps_nix_values(self) -> None:
        generated = b"OPENROUTER_API_KEY=nix-provider-key\n"
        previous = (
            b"DISCORD_BOT_TOKEN=runtime-discord-token\n"
            b"DISCORD_ALLOWED_USERS=123456789\n"
            b"OPENROUTER_API_KEY=old-runtime-key\n"
        )

        self.assertEqual(
            generated
            + b"DISCORD_BOT_TOKEN=runtime-discord-token\n"
            + b"DISCORD_ALLOWED_USERS=123456789\n",
            MERGER.merge_environment(generated, previous),
        )

    def test_preserves_export_syntax_and_handles_missing_final_newline(self) -> None:
        generated = b"# managed by Nix"
        previous = b"export DISCORD_BOT_TOKEN=runtime-discord-token"

        self.assertEqual(
            generated + b"\n" + previous + b"\n",
            MERGER.merge_environment(generated, previous),
        )

    def test_merge_is_idempotent(self) -> None:
        generated = b"OPENROUTER_API_KEY=nix-provider-key\n"
        previous = b"DISCORD_BOT_TOKEN=runtime-discord-token\n"
        merged = MERGER.merge_environment(generated, previous)

        self.assertEqual(merged, MERGER.merge_environment(merged, previous))

    def test_drops_keys_removed_from_declarative_environment(self) -> None:
        generated = b"NEW_PROVIDER_KEY=nix-new-key\n"
        previous = b"DISCORD_BOT_TOKEN=runtime-discord-token\nOLD_PROVIDER_KEY=stale-key\n"

        self.assertEqual(
            generated + b"DISCORD_BOT_TOKEN=runtime-discord-token\n",
            MERGER.merge_environment(generated, previous, {b"OLD_PROVIDER_KEY"}),
        )

    def test_file_merge_updates_manifest_and_keeps_file_permissions(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            destination = root / ".env"
            previous = root / ".env.previous"
            manifest = root / ".env-nix-managed-keys"
            destination.write_bytes(b"NEW_PROVIDER_KEY=nix-new-key\n")
            previous.write_bytes(b"DISCORD_BOT_TOKEN=runtime-discord-token\nOLD_PROVIDER_KEY=stale-key\n")
            manifest.write_bytes(b"OLD_PROVIDER_KEY\n")
            destination.chmod(0o640)

            MERGER.merge_file(destination, previous, manifest)

            self.assertEqual(
                b"NEW_PROVIDER_KEY=nix-new-key\nDISCORD_BOT_TOKEN=runtime-discord-token\n",
                destination.read_bytes(),
            )
            self.assertEqual(b"NEW_PROVIDER_KEY\n", manifest.read_bytes())
            self.assertEqual(0o640, stat.S_IMODE(destination.stat().st_mode))


if __name__ == "__main__":
    unittest.main()
