# Cua Spaces

Open **Cua Spaces** from the application launcher, or run `cua-spaces`.
The desktop configuration installs the app and `cua` on PATH, enables
rootless Podman and its user socket, and registers `cua mcp` with Codex.
The existing `cua-driver` MCP continues to control the host desktop.

`cua` automatically delegates Spaces-only commands such as `cua teleport`
to the app's bundled CLI. The wrapper sets `CUA_SPACES_CLI` unless you have
explicitly supplied another path. Preview a transfer with
`cua teleport manifest` before approving it; browser sessions can include
signed-in site data.

Sign in through the app when prompted. Account enrollment and device
confirmation require your interaction. This configuration does not enroll
the computer in a relay account or enable unattended desktop sharing.

Check the local runtime:

```sh
systemctl --user status podman.socket
cua runtime doctor
```

Create a local Linux desktop when needed:

```sh
cua sb create linux --on local --name my-agent --cpu 2 --memory 4GB --wait desktop
cua sb ls
```

Use a separate Space for each agent. The first creation downloads the Linux
image and consumes additional disk space. The Cua Spaces and Cua Sandboxes
skills are installed in `~/.agents/skills` for agents to discover. Reconnect
Codex's MCP servers after applying the configuration.

The app is packaged from the pinned upstream Debian release, with its ELF
dependencies adapted to NixOS and its polkit actions installed. It retains
the upstream browser sandbox. App updates come through this Nix configuration;
the writable in-app updater is disabled. Upstream officially supports Ubuntu
24.04 for the Linux app; NixOS and Hyprland are outside that support matrix.
The host CUA Hyprland plugin has its own limitations documented in
[CUA Hyprland plugin](cua-hyprland-plugin.md).

References: [installation](https://cua.ai/docs/spaces/guides/install) and
[local Spaces](https://cua.ai/docs/start-here/create-a-space-with-the-sdk).

## Prefer Tailscale for the server desktop

On artsxps, the `cua` wrapper routes work addressed to
`relay:space-b8fc63135c22a3db` through the registered direct endpoint
`http://100.75.156.101:8212` when its health check succeeds. The endpoint is a
Tailscale Serve TCP forward to the server's Docker port, available only within
the tailnet. It retains the Space's token authentication. The existing relay
registration stays enabled.

Codex's `cua mcp` registration uses this wrapper automatically. Each MCP call
with a `space` argument checks the route before dispatch. Shell commands,
file transfers, driver calls and teleport calls use the selected endpoint.
Stop, start, delete, remove and sharing operations retain the relay identity
so the host can manage the sandbox. CLI routing covers `cua sb exec`,
`cua sandbox exec`, `cua agent run` and `cua teleport push --sandbox` when the
explicit relay ID is supplied. Other CLI commands retain upstream behavior.

An unavailable direct endpoint selects the relay for that request. The next
request checks Tailscale again. The wrapper never retries an action after it
has been sent, because a lost response can leave a command or click completed.
A mid-action disconnection therefore returns an error; inspect state before
repeating it. Upstream teleport restrictions on sending sensitive data through
older relay images still apply.

Routes live in `~/.config/cua/routes.json`; tokens stay in CUA's separate
0600 credential store. To add another Space, register its authenticated
Tailscale endpoint with `cua spaces add`, then add its relay-to-direct mapping
in the artsxps Home Manager configuration. Machines without a routes file use
normal upstream routing. `CUA_ROUTE_POLICY=relay cua ...` forces the original
relay route for diagnosis.

The native Cua Spaces app uses its own connection manager and does not pass
through this agent wrapper. The browser desktop preview already runs over
Tailscale on port 8213. CUA's separate opt-in mesh is described in the
[relay security documentation](https://cua.ai/docs/spaces/guides/relay-security).

On lucidsserver, Tailscale persists this forward in its serve configuration:

```sh
tailscale serve --bg --tcp=8212 tcp://127.0.0.1:32768
```

If the desktop is deleted and recreated, check `docker port linux-desktop`
and update the forward and direct credential registration. Stopping and
starting the existing container retains its published port. Disable just this
forward with `tailscale serve --tcp=8212 off`; other viewers stay available.
