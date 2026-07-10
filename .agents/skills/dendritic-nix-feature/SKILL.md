---
name: dendritic-nix-feature
description:
  Add, remove, move, or redesign features in this repository's dendritic NixOS
  and Home Manager configuration. Use whenever a request changes packages,
  services, programs, hosts, overlays, flake inputs, or module composition—even
  if the user only says to install, enable, or configure something. Preserve the
  dendritic architecture and existing host behavior.
compatibility:
  Requires Nix with flakes, nixfmt, and this repository's
  flake-parts/import-tree layout.
---

# Dendritic Nix Feature

Extend the configuration without reintroducing path-coupled module trees or
argument pass-through.

## Inspect first

1. Read `AGENTS.md`, `README.md`, `flake.nix`, and `modules/module-options.nix`.
2. Read the affected feature and host modules before editing.
3. Run `git status --short --branch` and preserve unrelated changes.
4. Identify which existing systems should receive the feature.

## Choose the narrowest module group

| Target systems                       | Module group                  |
| ------------------------------------ | ----------------------------- |
| Both NixOS systems                   | `nixos.modules.common`        |
| Desktop systems                      | `nixos.modules.desktop`       |
| Only the XPS                         | `nixos.modules.artsxps`       |
| Only WSL                             | `nixos.modules.wsl`           |
| Both users' Home Manager evaluations | `homeManager.modules.common`  |
| Desktop Home Manager only            | `homeManager.modules.desktop` |

Create a distinct named deferred module only when hosts need to opt into the
feature independently.

## Implement the feature

Every new `modules/**/*.nix` file must be a top-level flake-parts module:

```nix
{ inputs, ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.example ];
      imports = [ inputs.example.homeModules.default ];
    };
}
```

Follow these design rules:

- Merge into an existing deferred module instead of adding an import-only
  aggregator.
- Close over top-level `inputs` or `config`; do not add `specialArgs` or
  `extraSpecialArgs`.
- Importing a repository-local module should enable its feature. Avoid local
  `enable` options unless a module must remain imported while disabled.
- Keep each file focused on one feature across every configuration class it
  affects.
- Keep host composition in `modules/hosts/`.
- Preserve intentionally disabled named modules unless the request explicitly
  enables them.
- Add overlays through `nixos.modules.common` when Home Manager uses global
  packages.

## Validate the change

Run the cheapest checks first and stop to diagnose failures:

```bash
nixfmt --check $(find . -type f -name '*.nix' -not -path './.git/*')
nix flake check --no-warn-dirty
```

Then build the affected host:

```bash
sudo nixos-rebuild build --flake /home/lucid/nixos#artsxps
```

For WSL-only changes, evaluate or dry-run `nixosConfigurations.nixos-wsl` as
well.

Do not switch the running system until the change is reviewed and committed
unless the user explicitly requests an immediate switch.

## Report

Summarize:

- module group and files changed
- validation commands and outcomes
- whether a build or switch was performed
- remaining warnings or manual steps
