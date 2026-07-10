# LikelyLucid NixOS configuration

This flake manages two systems:

- `artsxps` — the main NixOS desktop
- `nixos-wsl` — the WSL development environment

It uses the [dendritic pattern](https://github.com/mightyiam/dendritic): every
Nix file except `flake.nix` is a top-level flake-parts module. Feature files
contribute deferred NixOS or Home Manager modules, and host files compose those
modules into complete systems.

## Architecture

```text
flake.nix                       # Inputs and the flake-parts/import-tree entry point
modules/
├── module-options.nix          # nixos.modules, homeManager.modules, configurations
├── home-manager.nix            # Nested Home Manager integration
├── home.nix                    # Shared lucid Home Manager configuration
├── home/
│   ├── desktop.nix             # Desktop-only Home Manager configuration
│   └── wsl.nix                 # WSL-only Home Manager configuration
├── overlays.nix                # Shared package overlays
├── sops.nix                    # sops-nix integration
├── hosts/
│   ├── artsxps/
│   │   ├── configuration.nix   # artsxps module and host composition
│   │   └── hardware.nix        # artsxps hardware contribution
│   └── wsl/
│       └── configuration.nix   # WSL module and host composition
└── <feature>/                  # One feature per top-level module
```

`import-tree` recursively imports `modules/**/*.nix`. File paths describe
features; they do not determine whether a file is a NixOS or Home Manager
module.

### Module groups

| Group                         | Purpose                                   |
| ----------------------------- | ----------------------------------------- |
| `nixos.modules.common`        | Imported by both systems                  |
| `nixos.modules.desktop`       | Desktop NixOS features                    |
| `nixos.modules.artsxps`       | Machine-specific hardware and settings    |
| `nixos.modules.wsl`           | WSL-specific settings                     |
| `homeManager.modules.common`  | Home configuration shared by both systems |
| `homeManager.modules.desktop` | Desktop-only home configuration           |
| `homeManager.modules.wsl`     | WSL-only home configuration               |

Optional modules such as Firefox, Pandoc, and Plasma have their own names and
are not imported by either host.

## Extending the configuration

Add a feature by creating a top-level module under `modules/` and merging into
the narrowest existing group.

```nix
# modules/tools/example.nix
{ ... }:
{
  homeManager.modules.common =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.example ];
    };
}
```

For desktop NixOS configuration:

```nix
{ ... }:
{
  nixos.modules.desktop = {
    services.example.enable = true;
  };
}
```

Use the top-level `inputs` argument when a feature needs a flake input. Close
over that input in the deferred module instead of adding `specialArgs` or
`extraSpecialArgs`.

```nix
{ inputs, ... }:
{
  homeManager.modules.desktop = {
    imports = [ inputs.example.homeModules.default ];
  };
}
```

Do not add import-only aggregator files. Deferred modules with the same group
name merge automatically.

## R workstation

The R workstation is intentionally kept out of the global Home Manager profile
to reduce normal system rebuilds. Enter it on demand:

```bash
nix develop .#r
rstudio
```

For automatic project activation, add `use flake /home/lucid/nixos#r` to the
project's `.envrc`, then run `direnv allow`.

## Validation

The configured Git hooks automate validation:

- pre-commit formats staged Nix files and runs `deadnix`
- pre-push runs `statix`, `deadnix`, and `nix flake check`

Run the full checks manually before applying changes:

```bash
nixfmt --check $(find . -type f -name '*.nix' -not -path './.git/*')
statix check .
deadnix --fail .
nix flake check --no-warn-dirty
sudo nixos-rebuild build --flake /home/lucid/nixos#artsxps
```

Apply the main system after committing and pushing:

```bash
sudo nixos-rebuild switch --flake /home/lucid/nixos#artsxps
```

Evaluate the WSL configuration with:

```bash
nix build .#nixosConfigurations.nixos-wsl.config.system.build.toplevel --dry-run
```

## Repository workflow

1. Preserve unrelated working-tree changes.
2. Format and run `nix flake check`.
3. Build the affected host.
4. Commit and push the configuration.
5. Switch only after the commit is durable.

Changes to `~/dotfiles/` follow a separate commit/push/lock-update workflow
documented in `AGENTS.md`.
