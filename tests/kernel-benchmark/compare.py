#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def load(path: str) -> dict[str, dict]:
    try:
        data = json.loads(Path(path).read_text())
        return {item["command"]: item for item in data["results"]}
    except (OSError, json.JSONDecodeError, KeyError, TypeError) as error:
        raise ValueError(f"cannot load benchmark results from {path}: {error}") from error


def main() -> int:
    if len(sys.argv) != 3:
        print(f"usage: {Path(sys.argv[0]).name} BASELINE.json CANDIDATE.json", file=sys.stderr)
        return 2

    baseline = load(sys.argv[1])
    candidate = load(sys.argv[2])
    missing = baseline.keys() ^ candidate.keys()
    if missing:
        print(f"error: benchmark sets differ: {', '.join(sorted(missing))}", file=sys.stderr)
        return 1

    print(f"{'workload':34} {'baseline':>11} {'candidate':>11} {'change':>9}")
    print("-" * 70)
    changes = []
    for name, old in baseline.items():
        new = candidate[name]
        change = (new["mean"] / old["mean"] - 1) * 100
        changes.append(change)
        print(f"{name:34} {old['mean']:10.3f}s {new['mean']:10.3f}s {change:+8.1f}%")

    geometric_ratio = 1.0
    for change in changes:
        geometric_ratio *= 1 + change / 100
    overall = (geometric_ratio ** (1 / len(changes)) - 1) * 100
    print("-" * 70)
    print(f"{'geometric mean (lower is better)':58} {overall:+8.1f}%")
    print("Negative change means the candidate kernel was faster.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
