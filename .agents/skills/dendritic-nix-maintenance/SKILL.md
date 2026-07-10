---
name: dendritic-nix-maintenance
description:
  Maintain and repair this repository's dendritic Nix flake safely. Use for
  flake input updates, package/version maintenance, evaluation or rebuild
  failures, module moves, stale documentation, repository health checks, and
  preparing verified commits. For a switch-only request with no source change,
  use the dedicated NixOS rebuild workflow instead.
compatibility:
  Requires Git, Nix with flakes, nixfmt, and access to the configured NixOS
  hosts.
---

# Dendritic Nix Maintenance

Keep the flake evaluable, documented, and recoverable while preserving unrelated
work.

## Establish a baseline

1. Read `AGENTS.md` and `README.md`.
2. Run `git status --short --branch` and inspect existing diffs before editing.
3. Record which changes predate the task; do not discard or overwrite them.
4. Read `flake.nix`, `modules/module-options.nix`, the affected module, and its
   host composition.

## Preserve dendritic invariants

Check that:

- `flake.nix` remains the only Nix entry point.
- Every `modules/**/*.nix` file is a top-level module imported by `import-tree`.
- Lower-level modules live under declared `deferredModule` options.
- Feature modules merge into existing `common`, `desktop`, or host groups where
  appropriate.
- No `specialArgs`, `extraSpecialArgs`, or import-only aggregators are
  introduced.
- Flake inputs are consumed by top-level modules through lexical closure.

## Perform the smallest maintenance action

For input updates, update only the requested input when possible:

```bash
nix flake lock --update-input <input>
```

For evaluation failures:

1. Reproduce with `nix flake show --no-write-lock-file` or
   `nix flake check --no-warn-dirty`.
2. Read the complete option/module trace before editing.
3. Fix the earliest repository-owned definition in the trace.
4. Re-run the exact failing command before broader checks.

When adding untracked Nix files, remember that Git-backed flakes do not include
them until they are added to the index. Stage only intended files before
evaluating.

## Validate progressively

```bash
nixfmt --check $(find . -type f -name '*.nix' -not -path './.git/*')
nix flake show --no-write-lock-file
nix flake check --no-warn-dirty
sudo nixos-rebuild build --flake /home/lucid/nixos#artsxps
```

Also evaluate WSL when shared or WSL modules changed.

Treat pre-existing deprecation warnings separately from migration blockers.
Report them rather than widening scope unless the user asks for cleanup.

## Documentation and checkpoint

Update `README.md`, `AGENTS.md`, scripts, and path references when architecture
or file locations change.

Before switching:

1. Review `git diff --check` and the staged diff.
2. Commit the logical change with a descriptive message.
3. Push the commit when credentials and network access permit.
4. Switch only after a successful check/build and durable Git checkpoint.

Never claim a check, build, commit, push, or switch succeeded without command
output proving it.

## Report

Include:

- baseline dirty state and preserved changes
- files and inputs changed
- exact validation evidence
- commit/push/switch status
- residual warnings and rollback guidance
