# Nix Configuration Code Style Guidelines

## Directory Structure

```plaintext
└── likelylucid-nixos/
    ├── configuration.nix
    ├── flake.lock
    ├── flake.nix
    ├── hardware-configuration.nix
    ├── home.nix
    └── modules/
        ├── browsers/
        │   ├── browsers.nix
        │   ├── firefox.nix
        │   └── zen.nix
        ├── dev/
        │   ├── developer.nix
        │   ├── neovim.nix
        │   └── tmux.nix
        ├── notes/
        │   ├── notes.nix
        │   ├── obsidian.nix
        │   └── pandoc.nix
        └── window-manager/
            ├── hyprland.nix
            ├── plasma.nix
            └── window-manager.nix
````

## 1. Indentation

* Use **2 spaces** for indentation.

## 2. Naming Conventions

* Use **snake\_case** for variable and function names.
* Use **PascalCase** for module names.

## 3. Section Comments

Use ASCII comments to separate sections:

```nix
############################################
# SYSTEM CONFIGURATION
############################################

# Set the hostname for the system
networking.hostName = "my-server";

############################################
# HARDWARE CONFIGURATION
############################################

# Enable network manager
networking.networkmanager.enable = true;
```

## 4. Keep Configurations DRY

* Avoid repeating settings. Create reusable functions or variables where necessary.

## 5. Dotfiles Workflow

**Changes to `~/dotfiles/` must be committed + pushed to GitHub before a NixOS rebuild.**

The `dotfiles` flake input points to `github:LikelyLucid/dotfiles`, so Nix fetches the pinned commit — local changes won't survive unless pushed.

Workflow:

```bash
# 1. Make changes in ~/dotfiles/ (wallust templates, rofi, waybar, etc.)

# 2. Run wallust to generate colors (if applicable)
wallust run ~/dotfiles/media/wallpapers/Wallpaper\ 4.jpg

# 3. Commit and push
cd ~/dotfiles
git add -A
git commit -m "what changed"
git push

# 4. Update flake lock (optional, if dotfiles main branch advanced)
cd ~/nixos
nix flake lock --update-input dotfiles

# 5. Rebuild
sudo nixos-rebuild switch --flake /home/lucid/nixos#artsxps
```
