#!/usr/bin/env python3

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("check_dendritic", ROOT / "scripts/check-dendritic.py")
assert SPEC is not None and SPEC.loader is not None
CHECKER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = CHECKER
SPEC.loader.exec_module(CHECKER)


class DendriticPolicyTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary_directory.name)
        self.write("flake.nix", "{ outputs = _: { }; }\n")
        self.policy = {
            "homeManagerModuleGroups": ["common"],
            "nixosModuleGroups": ["common"],
            "hosts": {},
            "localOptionModules": [],
        }
        self.write("dendritic-policy.json", json.dumps(self.policy))

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def write(self, relative: str, content: str) -> None:
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    def messages(self) -> list[str]:
        return [finding.message for finding in CHECKER.validate_repository(self.root, parse=False)]

    def test_accepts_declared_deferred_group_and_masks_literals(self) -> None:
        self.write(
            "modules/example.nix",
            """{ inputs, ... }:
{
  nixos.modules.common = {
    example = \"specialArgs\";
    script = ''
      extraSpecialArgs
    '';
    source = inputs.example;
  };
}
""",
        )
        self.assertEqual([], self.messages())

    def test_rejects_unknown_group(self) -> None:
        self.write("modules/example.nix", "{ ... }:\n{\n  nixos.modules.unknown = { };\n}\n")
        self.assertTrue(any("unknown NixOS module group" in message for message in self.messages()))

    def test_rejects_plain_deferred_module(self) -> None:
        self.write("modules/example.nix", "{ pkgs, ... }:\n{\n  environment.systemPackages = [ pkgs.git ];\n}\n")
        self.assertTrue(any("unsupported top-level" in message for message in self.messages()))

    def test_rejects_argument_threading(self) -> None:
        self.write(
            "modules/example.nix",
            "{ ... }:\n{\n  nixos.modules.common = { specialArgs = { }; };\n}\n",
        )
        self.assertTrue(any("specialArgs" in message for message in self.messages()))

    def test_rejects_import_aggregator(self) -> None:
        self.write("modules/example.nix", "{ ... }:\n{\n  imports = [ ];\n}\n")
        self.assertTrue(any("import aggregators are forbidden" in message for message in self.messages()))

    def test_rejects_unapproved_local_options(self) -> None:
        self.write(
            "modules/example.nix",
            "{ ... }:\n{\n  nixos.modules.common = { lib, ... }: { options.example.enable = lib.mkEnableOption \"example\"; };\n}\n",
        )
        self.assertTrue(any("localOptionModules" in message for message in self.messages()))

    def test_rejects_nix_files_outside_module_tree(self) -> None:
        self.write("tests/fixture.nix", "{ }\n")
        self.assertTrue(any("Nix files must live under modules" in message for message in self.messages()))


if __name__ == "__main__":
    unittest.main()
