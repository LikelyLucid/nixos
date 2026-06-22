
# NixOS System Improvements

Add the following to the NixOS configuration:

## 1. systemd-oomd
Add `services.oomd.enable = true` to a system-level config. Check if it already exists.

## 2. auto-cpufreq
Add `services.auto-cpufreq.enable = true` with sensible defaults for a laptop (XPS 15 9530).

## 3. nix-direnv for R files only
The user has R files that they don't need on their system all the time. Add `nix-direnv` to their home-manager config but scope it to R projects only. Check if nix-direnv already exists in the config.

## 4. Check if atuin is already installed
Look for atuin in home.nix packages or shell config. Don't re-add if already present.

## 5. Add zoxide
Add `programs.zoxide.enable = true` to home-manager config. This replaces `cd` with smarter jumping.

## 6. Add swaync (sway notification center)
Add swaync to packages, create a wallust CSS template for it, add a wallust entry in wallust.toml. The template should use the standard wallust variables (background, foreground, color0-15). Create a config.json for swaync.

## 7. nix.gc.automatic
Add automatic garbage collection with a 30-day retention policy.

## 8. Rice swaync with wallust
Create a swaync wallust template at `~/dotfiles/wallust/templates/swaync.css` and add a wallust entry in `~/dotfiles/wallust/wallust.toml` targeting `~/.config/swaync/style.css`.

## Guidelines
- Follow the project's nix code style (2-space indent, snake_case, ASCII section comments)
- Do NOT change anything already working
- After each file edit, run `lens_diagnostics mode=delta` to check for errors
- Commit and push dotfiles changes to GitHub after edits
- Commit and push nixos changes to GitHub after edits
- Check for existing implementations before adding new things
