# NixOS System Improvements

## Status: ✅ COMPLETE

All changes have been implemented and committed.

## Changes Made

| Item | Status | Details |
|------|--------|---------|
| systemd-oomd | ✅ Already active | Running via systemd-oomd.service, no NixOS module needed |
| auto-cpufreq | ✅ Added | powersave on battery, performance on charger, turbo auto |
| nix-direnv | ✅ Added | Programs.direnv + nix-direnv enabled. User creates .envrc in R project dirs |
| atuin | ✅ Already present | programs.atuin.enable = true in zsh.nix |
| zoxide | ✅ Already present | programs.zoxide.enable = true in zsh.nix |
| swaync | ✅ Added | Replaces dunst, wallust CSS template created, config.json added |
| nix.gc.automatic | ⏭️ Removed | Conflicts with existing nh.clean.enable config |
| nix.auto-optimise-store | ✅ Added | Deduplicates nix store on rebuild |

## Files Modified

- hosts/artsxps/configuration.nix — auto-cpufreq, nix.settings
- home.nix — swaynotificationcenter, direnv, swaync config
- modules/window-manager/hyprland-config.nix — exec-once swaync
- dotfiles/wallust/wallust.toml — swaync template entry
- dotfiles/wallust/templates/swaync.css — new template

## Commits

- dotfiles: c8906fb "feat: add swaync wallust template"
- nixos: e078c75 "feat: add oomd, auto-cpufreq, nix gc, direnv, swaync"
- nixos: f7bebd5 "fix: correct swaync package name, remove redundant gc"
