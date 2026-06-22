---
name: test-config
description: Test NixOS/Hyprland service configs in isolation before rebuilding. Use when a service isn't starting, has format issues, or after adding a new service.
---

# Test Config

Test service configs in isolation before wrapping them in Nix. Prevents format issues like hyprpaper v0.8.4's block syntax change.

## Test hyprpaper

```bash
# 1. Create test config
cat > /tmp/hyprpaper-test.conf << 'EOF'
ipc=on
splash=false
preload=/path/to/wallpaper.jpg
wallpaper {
  monitor=
  path=/path/to/wallpaper.jpg
  fit_mode=cover
}
EOF

# 2. Run in isolation (3 second timeout)
timeout 3 hyprpaper --verbose -c /tmp/hyprpaper-test.conf 2>&1 | grep -i 'target\|load\|err\|layer'

# 3. Success = "configure layer with" appears
# 4. Failure = "no target" or "ERR" appears
```

## Test any hyprland service

```bash
# General pattern — replace <service> and <config>
cat > /tmp/<service>-test.conf << 'EOF'
<config contents>
EOF

timeout 3 <service> --verbose -c /tmp/<service>-test.conf 2>&1 | grep -i 'target\|load\|err\|layer\|ready\|start'
```

## Check journal logs after rebuild

```bash
# Systemd user services
journalctl --user -u <service> -n 30 --no-pager

# System services
journalctl -u <service> -n 30 --no-pager

# Hyprland exec-once (no systemd)
# Check if process is running
pgrep -a <service>
```

## Common issues to check

| Symptom | Likely cause |
|---|---|
| "no target" | Config format wrong (check package version) |
| "ERR" lines | Missing dependencies or GPU issues |
| Process not starting | `exec-once` not firing, or `graphical-session.target` inactive |
| Config not loading | Wrong path, or NixOS module generates different config |

## Check package version before writing config

```bash
# See what version you're running
nix eval nixpkgs#<package>.version --raw

# Find example configs in the nix store
find /nix/store -name "*.conf" -path "*<package>*" 2>/dev/null | head -5

# Read the test/example configs
cat /nix/store/<path>/tests/modules/services/<package>/<package>.conf
```

## Verify NixOS module options

```bash
# Check what options a NixOS module actually supports
cd ~/nixos && nix-instantiate --eval --expr '
  let pkgs = import <nixpkgs> {};
      mod = (pkgs.nixos { services.<service>.enable = true; });
  in builtins.attrNames mod.config.services.<service>
' 2>&1
```
