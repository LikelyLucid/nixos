#!/usr/bin/env python3
"""Fail closed when the repository violates its dendritic module policy."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import TypedDict, cast

POLICY_FILE = "dendritic-policy.json"
IGNORED_DIRECTORIES = {".direnv", ".git", ".pi-subagents", ".ralph", "result"}
PROHIBITED_TOKENS = (
    (re.compile(r"\bspecialArgs\b"), "specialArgs is forbidden; close over top-level inputs"),
    (re.compile(r"\bextraSpecialArgs\b"), "extraSpecialArgs is forbidden; close over top-level inputs"),
    (re.compile(r"\b_module\.args\b"), "_module.args is forbidden; use lexical closure or deferred groups"),
)
TOP_LEVEL_ASSIGNMENT = re.compile(
    r"^  ([A-Za-z_][A-Za-z0-9_-]*(?:\.[A-Za-z_][A-Za-z0-9_-]*)*)\s*="
)
LOCAL_OPTIONS = re.compile(r"\b(?:mkEnableOption|options\s*\.[A-Za-z_])")
INPUT_REFERENCE = re.compile(r"\binputs\s*\.")
INPUT_ARGUMENT = re.compile(r"\binputs\b")


class Policy(TypedDict):
    homeManagerModuleGroups: list[str]
    nixosModuleGroups: list[str]
    hosts: dict[str, str]
    localOptionModules: list[str]


@dataclass(frozen=True)
class Finding:
    path: str
    line: int
    message: str

    def render(self) -> str:
        return f"{self.path}:{self.line}: {self.message}"


def mask_literals_and_comments(source: str) -> str:
    """Mask Nix strings/comments while preserving offsets and newlines."""
    result = list(source)
    index = 0
    state = "code"
    block_depth = 0

    def mask(position: int) -> None:
        if result[position] != "\n":
            result[position] = " "

    while index < len(source):
        pair = source[index : index + 2]

        if state == "code":
            if source[index] == "#":
                mask(index)
                state = "line_comment"
                index += 1
            elif pair == "/*":
                mask(index)
                mask(index + 1)
                block_depth = 1
                state = "block_comment"
                index += 2
            elif pair == "''":
                mask(index)
                mask(index + 1)
                state = "indented_string"
                index += 2
            elif source[index] == '"':
                mask(index)
                state = "double_string"
                index += 1
            else:
                index += 1
        elif state == "line_comment":
            mask(index)
            if source[index] == "\n":
                state = "code"
            index += 1
        elif state == "block_comment":
            if pair == "/*":
                mask(index)
                mask(index + 1)
                block_depth += 1
                index += 2
            elif pair == "*/":
                mask(index)
                mask(index + 1)
                block_depth -= 1
                index += 2
                if block_depth == 0:
                    state = "code"
            else:
                mask(index)
                index += 1
        elif state == "double_string":
            mask(index)
            if source[index] == "\\" and index + 1 < len(source):
                mask(index + 1)
                index += 2
            elif source[index] == '"':
                state = "code"
                index += 1
            else:
                index += 1
        else:
            if pair == "''" and source[index + 2 : index + 3] not in {"'", "$"}:
                mask(index)
                mask(index + 1)
                state = "code"
                index += 2
            else:
                mask(index)
                index += 1

    return "".join(result)


def line_number(source: str, offset: int) -> int:
    return source.count("\n", 0, offset) + 1


def matching_brace(source: str, opening: int) -> int | None:
    depth = 0
    for index in range(opening, len(source)):
        if source[index] == "{":
            depth += 1
        elif source[index] == "}":
            depth -= 1
            if depth == 0:
                return index
    return None


def find_outer_module(source: str) -> tuple[int, int, int] | None:
    start_match = re.match(r"\s*\{", source)
    if start_match is None:
        return None
    arguments_open = start_match.end() - 1
    arguments_close = matching_brace(source, arguments_open)
    if arguments_close is None:
        return None
    cursor = arguments_close + 1
    while cursor < len(source) and source[cursor].isspace():
        cursor += 1
    if cursor >= len(source) or source[cursor] != ":":
        return None
    cursor += 1
    while cursor < len(source) and source[cursor].isspace():
        cursor += 1
    if cursor >= len(source) or source[cursor] != "{":
        return None
    result_close = matching_brace(source, cursor)
    if result_close is None:
        return None
    if source[result_close + 1 :].strip():
        return None
    return arguments_open, arguments_close, cursor


def top_level_assignments(source: str, result_open: int) -> list[tuple[str, int]]:
    assignments: list[tuple[str, int]] = []
    depth = 1
    offset = result_open + 1
    for number, line in enumerate(source[result_open + 1 :].splitlines(keepends=True), start=line_number(source, result_open + 1)):
        if depth == 1:
            match = TOP_LEVEL_ASSIGNMENT.match(line)
            if match is not None:
                assignments.append((match.group(1), number))
        depth += line.count("{") - line.count("}")
        offset += len(line)
        if depth == 0:
            break
    return assignments


def load_policy(root: Path) -> tuple[Policy | None, list[Finding]]:
    path = root / POLICY_FILE
    if not path.is_file():
        return None, [Finding(POLICY_FILE, 1, "required policy file is missing")]
    try:
        policy = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        return None, [Finding(POLICY_FILE, 1, f"cannot read policy: {error}")]

    required = {
        "homeManagerModuleGroups": list,
        "nixosModuleGroups": list,
        "hosts": dict,
        "localOptionModules": list,
    }
    findings: list[Finding] = []
    for key, expected_type in required.items():
        if not isinstance(policy.get(key), expected_type):
            findings.append(Finding(POLICY_FILE, 1, f"{key} must be a {expected_type.__name__}"))
    for key in ("homeManagerModuleGroups", "nixosModuleGroups", "localOptionModules"):
        value = policy.get(key)
        if isinstance(value, list) and not all(isinstance(item, str) for item in value):
            findings.append(Finding(POLICY_FILE, 1, f"{key} entries must be strings"))
    hosts = policy.get("hosts")
    if isinstance(hosts, dict) and not all(isinstance(key, str) and isinstance(value, str) for key, value in hosts.items()):
        findings.append(Finding(POLICY_FILE, 1, "hosts keys and values must be strings"))
    return (cast(Policy, policy) if not findings else None), findings


def iter_nix_files(root: Path) -> list[Path]:
    files: list[Path] = []
    for path in root.rglob("*.nix"):
        relative_parts = path.relative_to(root).parts
        if any(part in IGNORED_DIRECTORIES for part in relative_parts):
            continue
        if path.is_file() and not path.is_symlink():
            files.append(path)
    return sorted(files)


def parse_nix(path: Path, relative: str) -> list[Finding]:
    result = subprocess.run(
        ["nix-instantiate", "--parse", str(path)],
        check=False,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode == 0:
        return []
    message = result.stderr.strip().splitlines()[-1] if result.stderr.strip() else "Nix parse failed"
    return [Finding(relative, 1, message)]


def validate_assignment(
    relative: str,
    key: str,
    number: int,
    policy: Policy,
) -> list[Finding]:
    nixos_groups = set(policy["nixosModuleGroups"])
    home_groups = set(policy["homeManagerModuleGroups"])
    hosts = policy["hosts"]

    if key.startswith("nixos.modules."):
        parts = key.split(".")
        if len(parts) < 3 or parts[2] not in nixos_groups:
            return [Finding(relative, number, f"unknown NixOS module group in `{key}`")]
        if relative.startswith("modules/hosts/"):
            directory = relative.split("/")[2]
            expected_groups = {group for host, group in hosts.items() if directory in {host, group}}
            if parts[2] not in expected_groups:
                return [Finding(relative, number, f"host files may only contribute to {sorted(expected_groups)}")]
        return []

    if key.startswith("homeManager.modules."):
        parts = key.split(".")
        if len(parts) < 3 or parts[2] not in home_groups:
            return [Finding(relative, number, f"unknown Home Manager module group in `{key}`")]
        return []

    if key.startswith("nixos.configurations."):
        parts = key.split(".")
        if len(parts) < 3 or parts[2] not in hosts:
            return [Finding(relative, number, f"unknown host in `{key}`")]
        expected = f"modules/hosts/{hosts[parts[2]]}/configuration.nix"
        if relative != expected:
            return [Finding(relative, number, f"host `{parts[2]}` must be composed in {expected}")]
        return []

    if key in {"perSystem", "systems"}:
        return []
    if relative == "modules/module-options.nix" and key in {"options", "config.flake.nixosConfigurations"}:
        return []
    if key == "imports":
        return [Finding(relative, number, "top-level import aggregators are forbidden")]
    return [Finding(relative, number, f"unsupported top-level flake-parts contribution `{key}`")]


def validate_module(path: Path, root: Path, policy: Policy) -> list[Finding]:
    relative = path.relative_to(root).as_posix()
    source = path.read_text()
    masked = mask_literals_and_comments(source)
    findings: list[Finding] = []

    outer = find_outer_module(masked)
    if outer is None:
        return [Finding(relative, 1, "must be a top-level `{ ... }: { ... }` flake-parts module")]
    arguments_open, arguments_close, result_open = outer

    header = masked[arguments_open : arguments_close + 1]
    body = masked[result_open:]
    if INPUT_REFERENCE.search(body) and not INPUT_ARGUMENT.search(header):
        findings.append(Finding(relative, 1, "inputs must be captured by the top-level module argument"))

    for pattern, message in PROHIBITED_TOKENS:
        for match in pattern.finditer(masked):
            findings.append(Finding(relative, line_number(masked, match.start()), message))

    allowed_options = set(policy["localOptionModules"])
    options_match = LOCAL_OPTIONS.search(body)
    if options_match is not None and relative not in allowed_options and relative != "modules/module-options.nix":
        findings.append(
            Finding(
                relative,
                line_number(masked, result_open + options_match.start()),
                "repository-local options require an explicit localOptionModules policy exception",
            )
        )

    assignments = top_level_assignments(masked, result_open)
    if not assignments:
        findings.append(Finding(relative, 1, "module has no supported top-level contribution"))
    for key, number in assignments:
        findings.extend(validate_assignment(relative, key, number, policy))
    return findings


def validate_repository(root: Path, *, parse: bool = True) -> list[Finding]:
    policy, findings = load_policy(root)
    if policy is None:
        return findings

    nix_files = iter_nix_files(root)
    relative_files = {path.relative_to(root).as_posix() for path in nix_files}
    if "flake.nix" not in relative_files:
        findings.append(Finding("flake.nix", 1, "flake.nix must be the repository entry point"))

    for relative in sorted(relative_files - {"flake.nix"}):
        if not relative.startswith("modules/"):
            findings.append(Finding(relative, 1, "Nix files must live under modules/; flake.nix is the only exception"))

    for path in nix_files:
        relative = path.relative_to(root).as_posix()
        if parse:
            findings.extend(parse_nix(path, relative))
        if relative.startswith("modules/"):
            findings.extend(validate_module(path, root, policy))

    hosts = policy["hosts"]
    for host, directory in hosts.items():
        expected = f"modules/hosts/{directory}/configuration.nix"
        if expected not in relative_files:
            findings.append(Finding(expected, 1, f"policy host `{host}` has no composition module"))

    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", default=".", type=Path)
    parser.add_argument("--skip-nix-parse", action="store_true", help=argparse.SUPPRESS)
    arguments = parser.parse_args()
    root = arguments.root.resolve()

    findings = validate_repository(root, parse=not arguments.skip_nix_parse)
    if findings:
        print("dendritic policy violations:", file=sys.stderr)
        for finding in sorted(set(findings), key=lambda item: (item.path, item.line, item.message)):
            print(f"  {finding.render()}", file=sys.stderr)
        return 1

    print(f"dendritic policy: {len(iter_nix_files(root)) - 1} modules conform")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
