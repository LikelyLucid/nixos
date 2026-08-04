# Nix configuration guidelines

## Architecture

This repository follows the
[dendritic pattern](https://github.com/mightyiam/dendritic).

- `flake.nix` is the only Nix entry point.
- Every `modules/**/*.nix` file is a top-level flake-parts module.
- `import-tree` imports the module tree automatically.
- Features merge into deferred modules declared in `modules/module-options.nix`.
- `dendritic-policy.json` is the allowlist for module groups, hosts, and the rare
  repository-local option module.
- Hosts compose named modules in `modules/hosts/`.
- Do not introduce `specialArgs`, `extraSpecialArgs`, or import-only
  aggregators. Top-level modules can close over `inputs` and other top-level
  configuration values.

```text
flake.nix
modules/
├── module-options.nix
├── home-manager.nix
├── home.nix
├── home/{desktop,wsl}.nix
├── overlays.nix
├── hosts/
│   ├── artsxps/{configuration,hardware}.nix
│   ├── generic/{configuration,hardware-configuration}.nix
│   └── wsl/configuration.nix
└── <feature>/*.nix
```

Use these groups unless a feature needs a genuinely distinct reusable module:

- `nixos.modules.common`
- `nixos.modules.desktop`
- `nixos.modules.artsxps`
- `nixos.modules.generic`
- `nixos.modules.wsl`
- `homeManager.modules.common`
- `homeManager.modules.desktop`
- `homeManager.modules.wsl`

Importing a named module enables it. Avoid `enable` options for repository-local
composition unless a module must be imported while disabled.

## Style

- Use 2-space indentation and run `nixfmt`.
- Use `snake_case` for local variables and functions.
- Keep one feature per file.
- Keep file paths feature-oriented; do not organize files by module class.
- Prefer a small deferred-module contribution over a new abstraction.
- Preserve existing section comments when changing established modules.

## Adding a feature

```nix
{ inputs, ... }:
{
  homeManager.modules.desktop =
    { pkgs, ... }:
    {
      imports = [ inputs.example.homeModules.default ];
      home.packages = [ pkgs.example ];
    };
}
```

Merge into an existing group when all hosts in that group should receive the
feature. Create a distinct named module only when hosts need to opt into it
independently.

## Verification

Before claiming success:

```bash
nixfmt --check $(find . -type f -name '*.nix' -not -path './.git/*')
statix check .
deadnix --fail .
nix flake check --no-warn-dirty
sudo nixos-rebuild build --flake /home/lucid/nixos#artsxps
```

The pre-commit hook validates an isolated snapshot of the Git index. It rejects
formatting drift, dendritic policy violations, Statix findings, and dead code
without touching or staging unstaged edits. Install it in a new clone with
`scripts/install-git-hooks.sh`. The pre-push hook repeats the architecture and
static checks, then runs `nix flake check`.

For WSL-only work, also evaluate or dry-run `nixosConfigurations.nixos-wsl`.

The R workstation is available through `nix develop .#r` rather than the global
Home Manager profile.

## Git checkpoints

Commit and push after every logical change. Rebuilds apply the working tree
as-is, so an uncommitted rebuild has no durable rollback point.

## Dotfiles workflow

Changes to `~/dotfiles/` must be committed and pushed before a NixOS rebuild
because the `dotfiles` input is pinned in `flake.lock`.

```bash
cd ~/dotfiles
wallust run ~/dotfiles/media/wallpapers/wallpaper.jpg  # when applicable
git add -A
git commit -m "describe the change"
git push

cd ~/nixos
nix flake lock --update-input dotfiles
nix flake check --no-warn-dirty
sudo nixos-rebuild switch --flake /home/lucid/nixos#artsxps
```
