#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def load(path: Path) -> dict:
    try:
        with path.open(encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, json.JSONDecodeError) as error:
        raise SystemExit(f"failed to read {path}: {error}") from error


def keymap_id(keymap: dict) -> tuple[str, str, str]:
    return (keymap["mode"], keymap["lhs"], keymap["desc"])


def compare(baseline: dict, candidate: dict) -> dict:
    intended_option_values = {
        "clipboard": "unnamedplus",
        "laststatus": 3,
    }
    option_differences = {
        name: {"expected": intended_option_values.get(name, value), "candidate": candidate["options"].get(name)}
        for name, value in baseline["options"].items()
        if candidate["options"].get(name) != intended_option_values.get(name, value)
    }

    ignored_keymaps = {
        ("n", " cm", "Mason"),
    }
    baseline_maps = {keymap_id(keymap) for keymap in baseline["keymaps"]} - ignored_keymaps
    candidate_maps = {keymap_id(keymap) for keymap in candidate["keymaps"]}
    missing_maps = sorted(baseline_maps - candidate_maps)

    ignored_commands = {
        "Lazy",
        "MarkdownPreview",
        "MarkdownPreviewStop",
        "MarkdownPreviewToggle",
        "Mason",
        "TSInstall",
        "TSLog",
        "TSUninstall",
        "TSUpdate",
    }
    baseline_commands = set(baseline["commands"]) - ignored_commands
    candidate_commands = set(candidate["commands"])

    ignored_plugins = {
        "LazyVim",
        "lazy.nvim",
        "mason-lspconfig.nvim",
        "mason.nvim",
    }
    baseline_plugins = set(baseline["plugins"]) - ignored_plugins
    candidate_plugins = set(candidate["plugins"])

    missing_capabilities = sorted(
        name
        for name, capability in baseline["capabilities"].items()
        if capability["available"] and not candidate["capabilities"].get(name, {}).get("available", False)
    )

    report = {
        "colorscheme": {
            "baseline": baseline["colorscheme"],
            "candidate": candidate["colorscheme"],
            "matches": baseline["colorscheme"] == candidate["colorscheme"],
        },
        "missingCapabilities": missing_capabilities,
        "missingCommands": sorted(baseline_commands - candidate_commands),
        "missingKeymaps": [
            {"mode": mode, "lhs": lhs, "desc": desc}
            for mode, lhs, desc in missing_maps
        ],
        "missingParsers": sorted(set(baseline["parsers"]) - set(candidate["parsers"])),
        "missingPlugins": sorted(baseline_plugins - candidate_plugins),
        "optionDifferences": option_differences,
    }
    report["ok"] = not any(
        (
            not report["colorscheme"]["matches"],
            report["missingCapabilities"],
            report["missingCommands"],
            report["missingKeymaps"],
            report["missingParsers"],
            report["missingPlugins"],
            report["optionDifferences"],
        )
    )
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare LazyVim and NixVim runtime snapshots")
    parser.add_argument("baseline", type=Path)
    parser.add_argument("candidate", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    report = compare(load(args.baseline), load(args.candidate))
    rendered = json.dumps(report, indent=2, sort_keys=True)
    if args.output:
        args.output.write_text(rendered + "\n", encoding="utf-8")
    print(rendered)
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
