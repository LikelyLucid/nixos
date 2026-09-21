# NixOS Workstation Feature Roadmap

> **For Hermes:** Treat this as a roadmap. Before implementing a feature, turn that slice into a focused implementation plan and verify it independently.

**Goal:** Evolve `artsxps` from an already capable AI-first Wayland workstation into a recoverable, policy-aware, low-maintenance operating system with coherent laptop and development workflows.

**Architecture:** Keep the current dendritic pattern: each capability contributes to the narrowest existing deferred module group, without feature-local `enable` options or import aggregators. Prefer small NixOS/Home Manager modules plus narrow scripts and systemd units. Extend the existing Eww control center rather than adding a second system dashboard.

**Tech Stack:** NixOS unstable, flake-parts/import-tree, Home Manager, sops-nix, systemd, NetworkManager/nftables, Hyprland/UWSM, Eww/Waybar, Tailscale, Restic, Podman.

---

## Executive verdict

The workstation is not short of applications. It already has a strong desktop, laptop, development, AI-agent, media, connectivity, and peripheral foundation. The next work should focus on **recovery, trust boundaries, lifecycle automation, and context-aware workflows** rather than adding a random package list.

There is one **incident to handle before feature work**: the GitHub repository is public, and an independently verified Gitleaks scan found three likely historical credentials in reachable commit `b9404bdb5fe1876c04f7730f8382870480df9d81`. Do not expose the values while investigating. Rotate/revoke the affected credentials first, review access logs, and only then coordinate a destructive history rewrite.

After that incident, the three capabilities it should have first are:

1. A real, tested, off-device recovery path.
2. Network/service policy that changes with trust context instead of exposing LAN services everywhere.
3. A safe update/health pipeline that detects problems before a manual switch.

## Current system evidence

### Strong existing foundation

- Dendritic flake architecture with shared, desktop, and host-specific deferred modules: `flake.nix`, `modules/module-options.nix`, `dendritic-policy.json`.
- Nix lifecycle basics: flakes, store optimisation, `nh` cleanup, five retained recent generations: `modules/system/base.nix:9-38`.
- Native Wayland-first Hyprland desktop with UWSM, greetd, portals, lock/idle handling, screenshots, clipboard history, OSD, notifications, monitor configuration, and system controls: `modules/window-manager/hyprland.nix`, `modules/window-manager/hyprland-config.nix`, `modules/window-manager/session-services.nix`.
- Rich Eww control center already exposes resource health, failed service count, network/Tailscale details, displays, media, privacy sensors, mounts, development capability status, and Nix generation state: `/home/lucid/dotfiles/eww/scripts/shell-state.py:75-315`.
- Mature laptop support: TLP profiles, 75-80% battery thresholds, thermald, fwupd, brightness-on-battery policy, SMART, NVMe tools, fstrim, zram, OOM handling, and IRQ balancing: `modules/hosts/artsxps/configuration.nix:99-211`, `modules/power/battery-health.nix`, `modules/hardware/storage-health.nix`.
- Connectivity and peripherals: Tailscale SSH/client routing, Syncthing, KDE Connect, Bluetooth, printing/scanning, removable media, Thunderbolt authorization, and JuiceFS: `modules/networking/tailscale.nix`, `modules/home/desktop.nix:147-203`, `modules/hardware/printing.nix`, `modules/filesystems/removable-media.nix`, `modules/hardware/thunderbolt.nix`, `modules/filesystems/juicefs.nix`.
- Strong developer/agent environment: direnv/nix-direnv, Node/pnpm/Bun/Go/Python/uv, Nix tooling, Git/delta/fzf/Atuin, tmux persistence, Yazi, NixVim, Hermes, Herdr, and multiple coding agents: `modules/home.nix`, `modules/dev/`, `modules/tools/yazi.nix`, `modules/ai/`.
- Secrets foundation with sops-nix and GNOME keyring: `modules/sops.nix`, `modules/secrets.nix`, `modules/security/keyring.nix`.

### Material gaps confirmed during the audit

- The repository is public and the historical commit above remains reachable from `origin/main`. Gitleaks reports one historical API-key finding and two historical hard-coded credential findings. Rotation must precede history rewriting because deleting Git history does not invalidate an already copied secret.
- The current dirty worktree does not pass its own dendritic architecture checker: `modules/hosts/artslaptop/configuration.nix:1` uses an outer `let`, while policy requires a direct top-level `{ ... }: { ... }` flake-parts module. Finish or correct that in-progress host work before layering feature branches on top.
- The Restic timer exists, but `/etc/restic/repository` and `/run/secrets/restic-password` are both absent. The backup service therefore skips cleanly and no off-device backup is currently proven. Existing scope only covers `/home/lucid`, not Hermes state under `/var/lib/hermes/.hermes`: `modules/backups/restic.nix:8-44`, `docs/backups.md`.
- The Linux root is an unencrypted ext4 partition. Live storage shows no LUKS layer. The repository already records this as a reinstall boundary: `modules/hosts/artsxps/hardware.nix:30-44`, `docs/security.md:6-18`.
- Secure Boot is disabled, while TPM2 support is present. The current bootloader is systemd-boot.
- The Goodix `27c6:63ac` fingerprint reader is present, but `fprintd` is not installed or active. The existing security note correctly requires a disposable enrollment test before touching PAM: `docs/security.md:20-30`.
- XWayland remains enabled and X11 cursor integration is enabled even though the active desktop had no XWayland clients during inspection: `modules/window-manager/hyprland.nix:26-30`, `modules/appearance/desktop-theme.nix:82-90`.
- Syncthing ports are allowed globally at the host firewall, Avahi opens its firewall access, and the host separately allows TCP 22 even though remote administration already uses Tailscale SSH: `modules/hosts/artsxps/configuration.nix:74-83`, `modules/hardware/printing.nix:9-13`, `modules/networking/tailscale.nix:9-17`.
- The main desktop has no rootless Podman/Docker runtime. The existing Eww development panel explicitly reports Docker/Podman availability, so container support has a ready UI seam: `/home/lucid/dotfiles/eww/scripts/shell-state.py:235-243`.
- The laptop exposes a working ambient-light sensor (`iio:device0`, `als`) but the configuration has no adaptive-brightness service. It also has no explicit low-battery notification/emergency policy or hibernation path.
- The desktop has a polished screenshot/annotation flow but no native-Wayland screen-recording workflow for demos, bug reports, or UI review.
- The Eww health panel reports immediate metrics but not backup age, last backup/check result, SMART/NVMe health, update/build status, or persistent state transitions: `/home/lucid/dotfiles/eww/scripts/shell-state.py:75-102,257-264`.
- There is no repository CI workflow or governed flake-update proposal flow. Local Git hooks are strong, but they only run on the machine initiating a commit/push: `README.md:125-155`.
- A pure `nix flake check --no-build` currently fails at the Copilot unfree-license boundary; it only passes when evaluation is made impure with `NIXPKGS_ALLOW_UNFREE=1`. CI should fix the predicate rather than normalize impure evaluation. Deployed dotfiles also use mutable out-of-store links even though a locked `dotfiles` input exists: `modules/dev/nixvim.nix`, `modules/dotfiles.nix:10-38`.
- The AI automation boundary is intentionally broad: Hermes runs as the interactive user with secrets, Wayland/DBus/browser access and input injection; Helium is both the personal default browser and a continuously debug-enabled CDP target; `lucid` belongs to `input` and `uinput`. This deserves explicit containment rather than generic systemd hardening: `modules/ai/hermes-agent.nix`, `modules/browsers/helium.nix:24-32`, `modules/system/ydotool.nix`.
- Privacy residue needs policy: committed `error.log` contains account/environment metadata, clipboard history persists globally, removable media automounts, and two SOPS recipient configurations can drift: `error.log`, `modules/window-manager/session-services.nix:6-10`, `modules/filesystems/removable-media.nix:8-13`, `.sops.yaml`, `secrets/.sops.yaml`.
- AT-SPI is enabled, but no screen reader, magnifier, high-contrast/text-scale profile, reduced-motion mode, or explicitly composed accessible fallback session exists. This is optional unless needed, but should be a coherent profile rather than scattered packages.
- Custom services are functional but mostly unsandboxed. `systemd-analyze security` reports broad exposure for `home-remote-access.service` and `juicefs.service`; Hermes also has a broad score, although it runs as the unprivileged `lucid` user and intentionally needs home, network, DBus, and desktop access.

## Prioritized feature portfolio

| Priority | Capability | Value | Effort | Main dependency |
| --- | --- | --- | --- | --- |
| P-1 | Rotate leaked historical credentials and purge public history | Critical | Medium-High | Identify owners, rotate first, coordinate force-push |
| P0 | Activate and prove off-device Restic recovery | Very high | Medium | Choose backup destination and credentials |
| P0 | Trusted-network/service policy | Very high | Medium | Decide which services need LAN versus Tailscale |
| P0 | Safe update, CI, and rollback preview pipeline | High | Medium | Decide local-only vs hosted CI/update proposals |
| P1 | Health Center 2.0 with persistent alerts | High | Medium | Backup/update status producers |
| P1 | Activity and docking profiles | High | Medium | Define desired work/study/mobile/presentation states |
| P1 | Rootless Podman development runtime | High | Small-Medium | Validate project compatibility |
| P1 | Laptop power safety: travel charge, adaptive brightness, low-battery guard | High | Medium | Narrow privileged action boundary and ALS tuning |
| P2 | Native-Wayland recording workflow | Medium | Small | Choose lightweight recorder versus OBS |
| P1 | Native-Wayland completion and XWayland removal | Medium-High | Small-Medium | Audit dormant applications, especially OnlyOffice |
| P1 | Agent/browser/input trust-boundary hardening | Very high | Medium-High | Preserve existing Helium review workflow while separating personal sessions |
| P1 | Custom service sandboxing pass | Medium-High | Medium | Service-specific capability tests |
| P2 | Capture-to-knowledge workflow | Medium-High | Medium | Proven backups and explicit opt-in capture |
| P2 | Desktop privacy/accessibility profiles | Situationally high | Medium | Define retention, mounting, and accessibility needs |
| P2 | Fingerprint authentication experiment | Medium | Small | Successful enrollment/match test |
| P2 | Secure Boot with managed signing keys | High | Medium-High | Recovery keys and dual-boot validation |
| P2 | On-demand Wayland remote desktop over Tailscale | Medium | Medium | Confirm remote-view requirement |
| Future reinstall | LUKS2 + Btrfs/disko recovery layout | Very high | High | Proven backup/restore and reinstall window |

---

## Phase 0: Credential incident response

### Feature 0: Rotate, purge, and prevent recurrence

**Outcome:** Historical credentials are invalid, public history no longer contains them, and future pushes fail closed on secret findings.

**Likely files after rotation:**
- Modify: `.githooks/pre-commit`
- Modify: `.githooks/pre-push`
- Create: `.github/workflows/secret-scan.yml` if hosted CI is accepted
- Modify: `.gitignore`
- Remove from tracking: `error.log` after checking whether it contains any additional sensitive runtime metadata
- Modify: `README.md` or create a short credential-rotation runbook

**Order is mandatory:**
1. Identify the providers/accounts represented by the three findings without copying the values into chat, tickets, shell history, or new files.
2. Revoke or rotate all affected credentials and invalidate related sessions.
3. Review provider/Vaultwarden access logs for unauthorized use.
4. Scan all branches and tags again with Gitleaks.
5. Prepare a `git filter-repo` rewrite that removes the affected historical paths/values, then coordinate the required force-push and collaborator re-clone/reset. Do not run this as part of ordinary feature work.
6. Add redacted Gitleaks checks to pre-commit/pre-push and CI, including full-history scanning on protected-branch CI.
7. Verify the old commit and findings are absent from every public branch/tag while the rotated credentials remain unusable.

**Acceptance:** Provider-side rotation is confirmed; a full redacted Gitleaks scan of all retained history is clean; GitHub branches/tags no longer reach the affected content; developer hooks and CI reject a seeded test secret.

---

## Phase 1: Recovery and trust foundations

### Feature 1: Activate and prove encrypted off-device recovery

**Outcome:** A failed SSD, stolen laptop, or broken generation can be recovered without relying on Syncthing or Git alone.

**Likely files:**
- Modify: `modules/backups/restic.nix`
- Modify: `modules/secrets.nix`
- Modify: `docs/backups.md`
- Modify: `/home/lucid/dotfiles/eww/scripts/shell-state.py`
- Modify: `/home/lucid/dotfiles/eww/widgets/shell.yuck`

**Scope:**
1. Choose an off-device target: preferably a Restic repository on `lucidsserver` reachable through Tailscale or reputable object storage.
2. Materialize the repository password with sops-nix and declaratively create the repository locator with mode `0600`.
3. Keep the current `/home/lucid` backup, then add a deliberate Hermes state set covering `/var/lib/hermes/.hermes` while excluding caches, logs, transient browser data, and regenerable package artifacts.
4. Add a monthly `restic check` and a lightweight snapshot-age/status producer.
5. Notify only on state transitions: failed backup, stale backup, failed check, recovery to healthy.
6. Add backup age/result to the existing Eww health/NixOS panel.
7. Complete and document a real test restore of representative home and Hermes files.

**Acceptance:** A remote snapshot exists, `restic check` succeeds, selected files restore into a clean temporary directory, and the control center reports a recent verified backup.

### Feature 2: Introduce trusted-network service policy

**Outcome:** Syncthing, discovery, administration, and any future remote desktop are reachable only through explicit trusted paths.

**Likely files:**
- Create: `modules/networking/trusted-services.nix`
- Modify: `modules/hosts/artsxps/configuration.nix`
- Modify: `modules/hardware/printing.nix`
- Modify: `modules/networking/tailscale.nix`
- Extend existing NetworkManager dispatcher logic in `modules/hosts/artsxps/configuration.nix` only if connection-aware LAN rules are required.

**Scope:**
1. Inventory required listeners: Syncthing, KDE Connect, mDNS/printing, Tailscale SSH, development servers, and any future WayVNC service.
2. Remove unused TCP 22 exposure unless a conventional SSH daemon is deliberately enabled.
3. Prefer Tailscale interface rules for administration and remote access.
4. Either make Syncthing Tailscale-only or open LAN discovery/sync only while connected to named trusted home profiles.
5. Keep mDNS/printing limited to trusted LAN use rather than every Wi-Fi network.
6. Add a read-only Eww summary showing trusted/untrusted state and which local services are exposed.

**Acceptance:** On an untrusted network, LAN scans cannot reach Syncthing/admin services; over Tailscale and the chosen home profile, required workflows still work.

### Feature 3: Add a safe update and CI pipeline

**Outcome:** Updates become reviewable changes with build evidence and rollback context, not an ad hoc lock-file bump followed by hope.

**Likely files:**
- Create: `.github/workflows/flake-check.yml` or an equivalent local-only CI module if hosted CI is not desired.
- Create: `modules/system/update-workflow.nix`
- Modify: `/home/lucid/dotfiles/eww/scripts/shell-state.py`
- Modify: `/home/lucid/dotfiles/eww/widgets/shell.yuck`
- Modify: `README.md`

**Scope:**
1. First fix the `artslaptop` module-shape failure and the Nixvim Copilot unfree predicate so architecture checks and a pure `nix flake check --no-build` pass without an impure global override.
2. Run architecture/static checks and `nix flake check` in CI for pushed commits and pull requests.
3. Add a clean-worktree update-preview command that updates inputs, builds the target, runs `nvd diff` against `/run/current-system`, and never switches automatically.
4. Preserve the repository rule: commit and push a verified checkpoint before switching.
5. Optionally use Renovate or a scheduled bot to propose lock-file PRs; never auto-merge or auto-switch unstable updates.
6. Expose current generation, pending built generation, closure delta, last check, and dirty-tree state in the existing NixOS panel.

**Acceptance:** A proposed update has reproducible check/build evidence and a visible package/closure diff before the user chooses to switch.

---

## Phase 2: Make the existing desktop shell operationally useful

### Feature 4: Health Center 2.0

**Outcome:** The current control center becomes a stateful early-warning system instead of a set of live numbers.

**Scope:**
- Add backup freshness/check result, SMART/NVMe health, battery wear/cycle count, failed system and user units, journal error trend, Nix build/update result, and storage thresholds.
- Produce a stable status document from systemd timers; keep Eww reads cheap and unprivileged.
- Alert only on transitions with cooldown and recovery notifications.
- Offer safe read-only drill-down commands. Keep destructive repair/rebuild actions out of Eww unless separately authorized through a narrow policy boundary.

**Likely files:**
- Create: `modules/system/health-status.nix`
- Modify: `modules/hardware/storage-health.nix`
- Modify: `/home/lucid/dotfiles/eww/scripts/shell-state.py`
- Modify: `/home/lucid/dotfiles/eww/widgets/shell.yuck`

### Feature 5: Activity and docking profiles

**Outcome:** One action establishes a coherent workstation state rather than independently changing displays, workspaces, power, notifications, and networking.

**Candidate profiles to confirm:**
- Work/agent: external display layout, persistent agent workspace, Herdr/Hermes/Helium placement, balanced or performance power.
- Study: Obsidian/Zotero/R workspace and calendar focus.
- Mobile/travel: internal display, power saver, direct network route, conservative background work.
- Presentation: external display, notifications suppressed, sleep inhibited, no private popups.

**Likely files:**
- Create: `modules/window-manager/activity-profiles.nix`
- Modify: `modules/agent/hyprland-workspace.nix`
- Modify: `modules/window-manager/hyprland-config.nix`
- Modify: `/home/lucid/dotfiles/eww/widgets/shell.yuck`
- Modify: `/home/lucid/dotfiles/eww/scripts/shell-action.sh`

**Important design constraint:** Choose one monitor-layout authority. Do not let `nwg-displays`, generated `monitors.lua`, Kanshi, and custom scripts race each other.

### Feature 6: Laptop power safety and travel mode

**Outcome:** Keep the normal 75-80% battery-care thresholds, support an explicit temporary full charge before travel, adapt brightness to the available sensor, and avoid silent critical-battery shutdown.

**Scope:**
- Add `Battery care` and `Charge to 100% once` actions.
- Use a tightly scoped root systemd service/polkit rule rather than general passwordless power commands.
- Restore normal thresholds automatically after the full-charge cycle or a configured expiry.
- Add adaptive brightness using the existing ALS, with smoothing, user override pause, minimum/maximum limits, and compatibility with the current 35% battery brightness cap. Do not let two brightness daemons fight.
- Add escalating low-battery notifications and a deliberate emergency action. Hibernation should wait for an explicit swap/resume design; until then, choose between suspend and clean poweroff based on data-loss risk.
- Display charge thresholds, health percentage, cycle count, and active temporary mode in the existing power panel.

**Likely files:**
- Modify: `modules/power/battery-health.nix`
- Modify: `modules/power/power-profiles.nix`
- Modify: `/home/lucid/dotfiles/eww/scripts/system-state.py`
- Modify: relevant Eww power widget files.

### Feature 6B: Native-Wayland recording workflow

**Outcome:** Capture a monitor or selected region with optional microphone audio, visible recording state, and predictable output files.

**Scope:**
- Use `wf-recorder` for the simple default path; add OBS only if scene composition/streaming is required.
- Provide region and monitor actions, a second invocation to stop, elapsed-time/recording indicators, and notifications with an Open action.
- Save to a dedicated `~/Videos/Recordings` directory and exclude disposable recordings from backups unless deliberately retained.
- Verify multi-monitor coordinates, PipeWire audio selection, no XWayland dependency, and clean finalization after suspend/logout.

**Likely files:**
- Create: `modules/media/screen-recording.nix`
- Modify: `modules/window-manager/hyprland-config.nix`
- Modify: `/home/lucid/dotfiles/eww/widgets/shell.yuck`

---

## Phase 3: Development and security alignment

### Feature 7: Rootless Podman workstation runtime

**Outcome:** Containers work on the main host without granting Docker-group-equivalent root access or polluting the base runtime environment.

**Likely file:**
- Create: `modules/dev/containers.nix`

**Scope:**
- Enable rootless Podman, Docker CLI compatibility only if projects need it, user networking/DNS, and weekly safe image/container pruning.
- Add `podman-compose` and optionally Distrobox only after a concrete workflow needs them.
- Avoid adding the user to a root-equivalent Docker group.
- Verify bind mounts, localhost publishing, Compose compatibility, and Nix development shells.
- The existing Eww development provider will automatically expose Podman availability.

### Feature 8: Complete native-Wayland migration

**Outcome:** XWayland is disabled unless evidence proves a required application cannot run natively.

**Likely files:**
- Modify: `modules/window-manager/hyprland.nix`
- Modify: `modules/window-manager/hyprland-config.nix`
- Modify: `modules/appearance/desktop-theme.nix`
- Audit wrappers in `modules/office/libreoffice.nix`, `modules/notes/obsidian.nix`, `modules/ai/omi.nix`, and desktop application modules.

**Scope:**
1. Exercise every regularly used GUI application and capture `hyprctl clients -j` XWayland state.
2. Fix native Wayland launch flags or replace the application only where necessary.
3. Remove the X11 cursor integration and XWayland-specific Hyprland rules once no required clients remain.
4. Disable `programs.hyprland.xwayland.enable` and verify portals, file pickers, clipboard, drag/drop, scaling, screen sharing, OnlyOffice, and Electron apps.

### Feature 9: Harden custom services without breaking intended capabilities

**Outcome:** Root and long-lived services receive only the filesystem, devices, capabilities, and network families they require.

**Likely files:**
- Modify: `modules/filesystems/juicefs.nix`
- Modify: `modules/hosts/artsxps/configuration.nix`
- Modify: `modules/ai/hermes-agent.nix`

**Scope:**
- Harden `home-remote-access.service` aggressively; it only needs to run `systemd-inhibit` and sleep.
- Give JuiceFS explicit `/dev/fuse`, mount, cache, network, and mountpoint permissions instead of unrestricted root service defaults. Test mounts, restart, shutdown, and network loss.
- Harden Hermes only with controls compatible with its intentional user-home, DBus, browser, network, and computer-use access. Do not apply `ProtectHome` or device restrictions blindly.
- Record before/after `systemd-analyze security` output, but treat functional tests as authoritative rather than chasing a score.

### Feature 10: Make agent and browser trust boundaries explicit

**Outcome:** Computer-use remains powerful for the requested existing Helium workflow, while unrelated personal browsing and raw input access are not ambiently exposed to every same-user process.

**Scope:**
- Keep the existing Helium review session where workflow requires it, but establish a clear personal-browser boundary—such as Zen for sensitive/personal sessions—or a separate Helium profile for automation. Never silently move reviews to a second session.
- Confirm CDP remains loopback-only and make its enabled state visible; avoid continuously enabling debugging on sessions containing high-value authenticated accounts where possible.
- Replace broad `input` membership with the narrowest working `/dev/uinput`/udev path; start ydotool only when computer-use needs it if latency and reliability remain acceptable.
- Split the Hermes environment file by provider/capability where practical, so browser or desktop automation does not inherit unrelated credentials.
- Add a visible privacy indicator and one action to stop browser debugging/input automation without stopping the desktop session.

**Likely files:**
- Modify: `modules/ai/hermes-agent.nix`
- Modify: `modules/browsers/helium.nix`
- Modify: `modules/system/ydotool.nix`
- Modify: existing Eww privacy widget files.

### Feature 11: Capture-to-knowledge pipeline

**Outcome:** An explicit action turns a selected screenshot or clipboard item into annotated/OCR Markdown with source metadata, routed to Obsidian and optionally linked to Zotero.

**Scope:**
- Reuse the current screenshot/annotation and clipboard workflows; do not add ambient capture.
- Prompt for destination and retention before writing to the vault.
- Preserve source URL/window/time metadata where available, and support Zotero attachment/citation linking as an optional second step.
- Implement only after Restic restore is proven, because it creates more irreplaceable personal knowledge state.

### Feature 12: Desktop privacy and accessibility profiles

**Outcome:** Privacy retention and accessibility are explicit user-selectable policies rather than incidental defaults.

**Scope:**
- Privacy: bound clipboard retention or purge on lock/logout; switch removable-media behavior to notification/prompt if desired; reconcile the duplicate SOPS recipient files; remove tracked diagnostic logs after history review.
- Accessibility: compose a high-contrast/text-scale/reduced-motion profile, add Orca/Speech Dispatcher and magnification only if useful, and retain a keyboard-accessible launcher and password-based fallback session.
- Stage USBGuard only in learning/audit mode before enforcement; do not risk blocking the dock, keyboard, storage, fingerprint reader, or recovery media.

---

## Phase 4: Optional security and remote-access experiments

### Fingerprint authentication

Run a disposable `fprintd-enroll` and repeated verify test first. If the Goodix reader is reliable, enable fingerprint authentication one PAM surface at a time with password fallback, starting with screen unlock or sudo rather than changing greetd and every authorization surface at once.

### Secure Boot

Add Lanzaboote/sbctl only after keys and recovery procedures are documented. Validate Windows dual boot, NixOS generation booting, unsigned recovery behavior, key backup, and firmware reset recovery. TPM2 is available, but TPM-bound secrets should wait until Secure Boot and recovery are proven.

### On-demand Wayland remote desktop

If visual remote access is useful, add a user-controlled WayVNC service bound only to the Tailscale address/interface, disabled by default, with a visible Eww indicator and automatic shutdown. Do not expose VNC on LAN/public interfaces.

### Next reinstall storage design

After Restic recovery is proven, plan a reinstall with LUKS2, a declarative disko layout, Btrfs subvolumes/snapshots, and an explicit hibernation strategy. Do not attempt an in-place encryption conversion during ordinary configuration work.

---

## Recommended delivery order

1. **Incident response:** rotate/revoke, review logs, rewrite public history, add secret scanning.
2. **Recovery:** choose target, activate Restic, include Hermes state, test restore.
3. **Trust:** restrict service exposure by network context.
4. **Lifecycle:** CI plus update/build/diff preview.
5. **Visibility:** Health Center 2.0 based on the first three capabilities.
6. **Workflow:** activity/dock profiles and battery travel mode.
7. **Developer isolation:** rootless Podman.
8. **Alignment:** finish native Wayland and service sandboxing.
9. **Experiments:** fingerprint, Secure Boot, remote desktop.
10. **Future reinstall:** LUKS2/Btrfs/disko.

## Global verification for every implemented slice

Run the repository gates from `AGENTS.md`:

```bash
nixfmt --check $(find . -type f -name '*.nix' -not -path './.git/*')
statix check .
deadnix --fail .
nix flake check --no-warn-dirty
sudo nixos-rebuild build --flake /home/lucid/nixos#artsxps
```

Then perform feature-specific runtime checks before offering the manual switch command. Changes to `/home/lucid/dotfiles` must be committed and pushed first, followed by a `dotfiles` input update in this flake. Do not switch an uncommitted configuration.

## Decisions required before implementation

1. Where should encrypted Restic data live: `lucidsserver`, object storage, or both?
2. Should Syncthing work over Tailscale only, or also on named trusted LANs?
3. Should CI/update proposals run on GitHub, locally, or both?
4. Which activity profiles and app/workspace placements are genuinely useful?
5. Is rootless Podman needed for current projects, or should it remain opt-in?
6. Which dormant GUI applications must be tested before disabling XWayland?
7. Is fingerprint convenience worth adding after the hardware test?
8. Is on-demand graphical remote access useful beyond existing Tailscale SSH and Hermes computer use?
