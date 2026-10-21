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
