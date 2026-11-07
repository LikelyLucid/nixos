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

SOPS installs the proxy key and endpoint in owner-only files for `lucid`.
Tailscale's key is root-only. The proxy configuration service reads these files
and updates the native client settings. T3 waits for tailnet enrollment.

To rotate a credential, edit the encrypted file with SOPS on your trusted admin
machine, commit and push it, then rebuild the server. The proxy secrets restart
the proxy configuration service when they change. Restart a client if it does
not reload the updated settings. Do not commit plaintext, private keys or
pairing links. Back up the host identity securely if it must survive a disk
replacement. To replace the host identity, enroll the new mounted target again.

The clients run as `lucid` and can read the runtime credential snapshot. This
host assumes trusted projects and agents operating as that user. It does not
isolate agents from one another.

## Model discovery

The server and desktop share the native client configuration and model refresh
service described in [Declarative agent proxy configuration](agent-proxy.md).
That guide covers client transports, credential rotation, diagnostics and
verification. A discovered model still requires a compatible working route on
the proxy; discovery alone does not prove inference works.

## T3 Code

The server profile imports `inputs.t3code.nixosModules.runtime-compat`, which
enables `nix-ld` for generic Linux executables downloaded by
T3 desktop SSH setup and `t3 service install`. Without it, those unpatched
runtimes fail with exit 127 on NixOS, even though the Nix-packaged server works.
NixOS's `t3-server` unit bootstraps and enables T3's native `t3code` user
service. The initial install downloads the current stable runtime through the
CLI from your `LikelyLucid/t3code-nix` input. Later Nix rebuilds retain T3's
installed version. The `t3` command dispatches to its writable launcher.

T3 starts with the lingering user manager at boot and restarts on failure.
State remains under `~/.t3`; back up this directory and your projects. This
configuration does not provision backups or automatic OS upgrades.

The backend binds to `127.0.0.1:3773` and requests Tailscale Serve HTTPS. A
Home Manager service drop-in supplies these settings without owning the main
unit, so T3 can update and restart itself. The T3 port is not open on the LAN.
Tailscale enrollment and HTTPS setup must be complete before pairing works.

```bash
t3 service status
t3 service restart
t3 update --yes
t3 pair --tailscale
```

Updates can also be requested through T3. No `npx t3 serve` session is needed.
The NixOS bootstrap retries a failed first install when networking returns.
`sudo systemctl restart t3-server` reconciles the user service when diagnosing
boot or secret changes; normal T3 service commands require no sudo.

For T3 Connect, authorize with `t3 connect --headless`, then run
`t3 service restart`. Check the link with `t3 connect status`.

The T3 Connect account must have a free machine slot. If startup reports the
managed tunnel limit, remove an unused environment from the account's T3
Connect page, then restart `t3-server`. Tailscale pairing and SSH do not consume
those cloud tunnel slots.

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

## Cua Spaces on the server

The headless server includes `cua`, the native Spaces runtime and rootless
Podman. The desktop application is not installed on this host. Its Podman socket
starts with the lingering user session, so local Linux Spaces can run without a
physical login.

Codex, Claude Code and OpenCode launch the `cua mcp` server automatically. Pi
receives the Cua Spaces, sandbox and volume skills in its server agent directory
and can use the `cua` CLI. Existing agent settings and plugins remain in place.

Sign in once from artslaptop with `cua auth login --remote`, then complete the
printed device approval on your signed-in computer. The server has its own Cua
device identity; proxy credentials do not sign it in to Cua. Run `cua spaces list`
to check which existing Spaces and machines this identity can access. Access to
another computer still follows the Cua account's grants and device approval.


## Browser automation

Both desktop and server profiles install agent-browser and Chromium. The server
uses system Chromium in headless mode, without a desktop session or a browser
download step. Codex, Claude Code and OpenCode receive its MCP server alongside
Cua; Pi receives the agent-browser skill in its isolated server agent directory.
The desktop keeps its existing browser integration and dashboard.

Browser sessions are isolated per agent or thread through the existing session
wrapper. Explicit `agent-browser --session <name>` still selects a named session.
Close unused sessions with `agent-browser close`.
