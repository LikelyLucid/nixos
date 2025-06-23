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

```
```
