# Coding agent server

`nixosConfigurations.agent-server` is an x86-64 physical-machine template. It
imports the shared CLI/TUI configuration and a separate `agent-server` module
group. It does not import the desktop group or start a display manager.

The shared tools include Zsh, Starship, Atuin, Git/Delta, tmux, Herdr, Neovim,
Yazi, the development runtimes and Nix tooling. The server adds GitHub CLI,
lazygit, compiler tools, Codex, Claude Code, OpenCode and Pi. The CLI runtimes
still take disk space, especially Neovim and language tooling; this is not a
minimal rescue system.

## Existing server: artslaptop

`nixosConfigurations.artslaptop` composes the headless agent-server group with
its verified physical disk UUIDs and Intel hardware. It preserves the hostname,
NetworkManager Wi-Fi profiles and the existing Tailscale machine identity.
Its existing SSH host public identity is enrolled in SOPS. The desktop group,
Bluetooth audio and laptop suspend behavior are removed from this host.

Build `.#nixosConfigurations.artslaptop.config.system.build.toplevel`, copy the
closure with `nix copy --to ssh://lucid@artslaptop`, then activate the resulting
system's `bin/switch-to-configuration switch` using sudo in an interactive SSH
terminal. Keep the previous system path for rollback. No disk formatting or
reinstallation is needed for this conversion.

## Install on another physical machine

1. Generate the target's hardware configuration from the installer with
   `nixos-generate-config --root /mnt`. Adapt the generated settings into
   `modules/hosts/agent-server/hardware.nix`, keeping its top-level flake-parts
   wrapper. The checked-in UEFI/ext4 disk labels are placeholders. They do not
   partition or erase a disk.
2. Check the architecture, boot mode, filesystem UUIDs and initrd drivers.
   Add any required firmware or CPU microcode for this machine.
3. Enroll the target's SSH host identity for SOPS before installing:

   ```bash
   nix run .#agent-server-enroll-secrets -- /mnt
   ```

   Run this from a checkout where your existing administrator age identity is
   available at `~/.secrets/age.agekey`, or set `SOPS_AGE_KEY_FILE` to its path.
   The helper generates the target's SSH host key if needed and adds its public
   age recipient to the encrypted server file. The private host key stays on
   the target. Commit and push the updated `.sops.yaml` and encrypted YAML.
4. Set a console password for `lucid` during installation. This is also the
   password for sudo. No password or passwordless sudo is configured here.
5. Build `nixosConfigurations.agent-server.config.system.build.toplevel`,
   then install using `nixos-install --flake /path/to/nixos#agent-server`.
   Keep a local console available until remote access has been verified.
6. On first boot, SOPS decrypts the three server values into `/run/secrets`.
   Tailscale enrolls automatically with the encrypted auth key and keeps its
   machine identity in `/var/lib/tailscale` across reboots. Enable MagicDNS and
   HTTPS certificates in the tailnet for the T3 HTTPS endpoint. If the stored
   enrollment key has expired, replace it in the encrypted file before first
   boot. Reboots of an enrolled machine do not need a new enrollment key.
7. Ensure the tailnet access policy permits your identity to reach this host
   and use Tailscale SSH as `lucid`. Test `ssh lucid@agent-server` from another
   tailnet device before leaving the machine unattended. For an unattended
   server, review the device key-expiry setting in the Tailscale admin console.

Tailscale SSH is enabled declaratively with `--ssh`. The firewall accepts SSH
only on `tailscale0`; ordinary password SSH and root login are disabled. The
existing `artsxps` public key is available for key-based SSH fallback. Tailnet
policy still controls who can use Tailscale SSH. No tailnet policy is modified
by this flake.

## Store credentials in SOPS

`secrets/agent-server.yaml` contains only the encrypted CLI proxy key, endpoint URL and
Tailscale enrollment key. The rest of the existing secrets file is not granted
to the server. GitHub receives ciphertext and public recipients. The machine's
SSH host private key decrypts its secrets automatically on boot; no separate
server age key or plaintext credential file needs to be copied.

SOPS installs the proxy key at `/run/secrets/agent-proxy-api-key`, owned by
`lucid` with mode `0400`. The endpoint has the same protection at
`/run/secrets/agent-proxy-base-url`. Tailscale's key is root-only. SOPS installs secrets during system activation,
before the T3 service starts. T3 also waits for tailnet enrollment. Agent launchers and the model
refresh timer read the SOPS-managed path automatically. Their version/help
probes work without credentials or proxy access.

To rotate a credential, edit the encrypted file with SOPS on your trusted admin
machine, commit and push it, then rebuild the server. The proxy secret restarts
T3 when it changes; restart existing interactive agent sessions too. Do not
commit plaintext, private keys or pairing links. Back up the host identity
securely if you want it to survive a disk replacement. To replace the host
identity, run the enrollment helper against the new mounted target again.

The proxy credential enters the child process environment and is
available to programs running as `lucid`. This host assumes trusted projects
and agents operating as that user. It does not isolate agents from one another.
Runtime catalogs contain the decrypted endpoint in files private to `lucid`.
Encrypting the Git version does not hide the address from clients using it.

## Model discovery

The refresh service queries
the SOPS-provided endpoint's `/models` route with bearer authentication at boot
and every 15 minutes. Launching an agent also refreshes a catalog older than
15 minutes. Failed refreshes retain the last successful generation. Initial
discovery requires a working credential and endpoint. Redirects are rejected.

- Codex receives a custom Responses provider and a generated model catalog.
  GPT/Codex and recognized OpenAI reasoning IDs populate its picker. Other
  IDs remain available in OpenCode and Pi. Codex requires the proxy to support
  `/v1/responses` for the selected model. When advertised, `gpt-6.1-sol` is
  the default, verified by a real request on artslaptop.
- Claude Code uses the proxy's Anthropic endpoint, native gateway model
  discovery where supported by the installed version, and discovered Claude
  IDs for its model allowlist and family defaults. The proxy must support
  `/v1/messages`; an OpenAI-only endpoint is insufficient.
- OpenCode v2 receives a generated Responses provider containing every
  discovered ID. It uses the same default model as Codex.
- Pi receives the same model IDs through a Responses provider, using an
  environment reference for its key and the same default as Codex. Its
  writable agent directory is `~/.local/state/agent-proxy/pi`, separate from
  the desktop's `~/pi-config` links. Put server-specific Pi extensions there.

The catalog reports IDs, not necessarily API compatibility, context windows,
reasoning levels or vision support. Discovery does not prove that every model
can run every client. The generated configuration does not invent those
capabilities. New sessions read updated catalogs; active sessions may need to
be restarted. The original per-user Codex/Claude configuration is not replaced.

Refresh diagnostics:

```bash
systemctl --user status agent-models-refresh.timer
journalctl --user -u agent-models-refresh.service
cat ~/.local/state/agent-proxy/current/models.json
```

The artslaptop inference checks passed for Codex, OpenCode v2 and Pi using
`gpt-6.1-sol`. The proxy advertised Claude IDs but rejected the tested Claude
requests upstream as unsupported. Claude Code is configured, but its inference
remains blocked until the proxy exposes a working Anthropic-compatible route.

## T3 Code

The server profile enables `nix-ld` for generic Linux executables downloaded by
T3 desktop SSH setup and `t3 service install`. Without it, those unpatched
runtimes fail with exit 127 on NixOS, even though the Nix-packaged server works.
The system-managed `t3-server` service already starts at boot; an additional
`t3 service install` is unnecessary for that service.

The server uses the pinned upstream standalone CLI release `0.1.3`, separately
from the desktop AppImage input. It runs as `lucid`, starts at boot and restarts
on failure. State lives under `~/.t3`; back up this directory and your projects.
This configuration does not provision backups or automatic OS upgrades.

The backend binds to `127.0.0.1:3773` and requests Tailscale Serve HTTPS. It
does not open the T3 port on the LAN. Tailscale enrollment and HTTPS setup must
be complete before remote pairing works. After enrolling:

```bash
sudo systemctl restart t3-server
systemctl status t3-server
t3 pair --tailscale
```

Use the pairing link from your desktop or phone on the tailnet. Pairing links
are credentials; do not publish them. Tailnet access and T3 pairing both apply.
Boot and refresh do not require an interactive login because `lucid` has linger
enabled. Suspend and hibernation are disabled.

For later upgrades, commit and push the configuration, build the server target,
then run the switch in an interactive terminal on that server. Do not switch
the desktop to this host definition.

## References

- [T3 remote access](https://github.com/pingdotgg/t3code/blob/main/docs/user/remote-access.md)
- [Codex configuration](https://developers.openai.com/codex/config-reference/)
- [Claude gateway configuration](https://code.claude.com/docs/en/llm-gateway)
- [OpenCode providers](https://opencode.ai/docs/providers/)
- [Pi model configuration](https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/docs/models.md)
- [Tailscale SSH](https://tailscale.com/docs/features/tailscale-ssh)
- [SOPS on NixOS](https://github.com/Mic92/sops-nix)
