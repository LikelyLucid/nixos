# NixOS Configuration Documentation

This directory contains NixOS configuration modules organized by functionality.

## Directory Structure

```
modules/
├── browsers/           # Web browser configurations
├── dev/               # Development environment
├── dotfiles.nix       # Dotfiles management
├── networking/        # Network services
├── notes/             # Note-taking applications
├── office/            # Office applications
├── secrets.nix        # Secret management with SOPS
├── security/          # Security and firewall configurations
├── system/            # System optimization and monitoring
├── university/        # Academic tools
└── window-manager/    # Desktop environment
```

## Module Overview

### Core System Modules
- **security/security.nix**: Firewall, AppArmor, automatic maintenance
- **system/monitoring.nix**: System monitoring tools and services
- **system/performance.nix**: Boot and runtime performance optimizations

### Development Environment
- **dev/developer.nix**: Development tools and Git configuration
- **dev/neovim.nix**: Neovim text editor setup
- **dev/tmux.nix**: Terminal multiplexer configuration
- **dev/zsh.nix**: Enhanced shell with modern tools

### Applications
- **browsers/**: Web browser configurations (Firefox, Zen)
- **notes/**: Note-taking tools (Obsidian, Pandoc)
- **office/**: Office suite (LibreOffice)
- **university/**: Academic tools (R, Zotero)

### System Services
- **networking/tailscale.nix**: VPN configuration
- **window-manager/**: Desktop environment setup

## Usage

Each module is self-contained and can be imported into host configurations:

```nix
imports = [
  ../../modules/security/security.nix
  ../../modules/system/monitoring.nix
  # ... other modules
];
```

## Configuration Style

All modules follow the style guidelines in `AGENTS.md`:
- 2-space indentation
- ASCII section comments
- snake_case for variables
- Organized imports and clear documentation