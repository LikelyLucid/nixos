# Use agent browsers

Open **Agent Browser Dashboard** from the application launcher, or run:

```bash
agent-browser-dashboard
```

The dashboard is available in your main browser at http://localhost:4848.
It starts with your graphical session and shows each agent's browser and activity.
Select a session to view its page and send mouse and keyboard input.

To help with login, interrupt the agent in its conversation first, then use the
dashboard. Tell the agent when you have finished so it can take a fresh snapshot
and continue. Dashboard input does not suspend an agent's command loop.

## Agent sessions

The installed `agent-browser` wrapper chooses a stable session from the thread
identity and the nearest agent process. Separate threads in one agent server
receive separate sessions. Separate agent processes also receive separate sessions.
In an ordinary terminal, the terminal's session ID is the fallback.

Child agents sharing their parent's process and thread identity need an explicit
session. The installed skill tells delegating agents to assign one to each child.
Agents can inspect their current session with:

```bash
agent-browser session
```

To select a session yourself:

```bash
agent-browser --session my-task open https://example.com
agent-browser --session my-task snapshot -i
agent-browser --session my-task close
```

Each session has a separate Helium instance and cookies. When the Helium profile
named `AGASSIST` exists, new default browsers receive a private copy of its login
storage, currently in `~/.config/net.imput.helium/Profile 1`. On machines without
Helium profile data or that named profile, browsers start clean automatically.
The copy includes cookies and site storage, with
cookie databases copied through SQLite's backup API while Helium stays open.
The source profile remains untouched. Browser caches, history, saved passwords,
extensions, desktop preferences, and open-tab restoration are excluded.
Helium uses its normal desktop keyring
to read copied cookies. The copy is deleted with the browser's temporary directory
on normal shutdown. Already-running agent browsers keep their existing profiles.

To start without the AgAssist login state:

```bash
AGENT_BROWSER_HELIUM_PROFILE=none agent-browser --session clean-test open about:blank
```

Explicit `--profile` paths and custom executable overrides retain their normal
behavior. No `npm install` or `agent-browser install` step is needed.
Use `--restore` to retain a session's authentication across browser restarts.
Close sessions when finished. The upstream default also closes headless sessions
after an hour without commands or dashboard input.

## Agent discovery

Home Manager installs the same browser skill into the shared `.agents` skill
directory and the Claude Code, OpenCode, and Pi skill directories. New conversations
discover it automatically. Restart existing conversations to refresh their skills.
The skill points to `agent-browser skills get core` for version-matched commands.

## Codex MCP servers

Home Manager registers `agent-browser` and `cua-driver` in Codex's user MCP
configuration during activation, using `codex mcp add`. Existing Codex settings
and other server entries remain intact. These two registrations are managed by
Nix and refreshed on activation. Start a new Codex session after changing them.

Agent-browser exposes its full MCP tool catalog, with the same automatic profile
reuse and clean fallback as the CLI. Each MCP process gets a separate default
browser session. Tools can select an explicit `session` when needed.
CUA connects to the existing user daemon at `~/.cache/cua-driver/cua-driver.sock`
with Wayland enabled. The daemon must be running for that MCP server to work.

Check registration with `codex mcp list`.

## Service maintenance

```bash
systemctl --user status agent-browser-dashboard
systemctl --user restart agent-browser-dashboard
journalctl --user -u agent-browser-dashboard
```

The dashboard listens on loopback only. Its session traffic passes through the
dashboard, so no session ports need forwarding. This setup does not expose it to
the network or attach agents to your live main browser.

The desktop Home Manager feature is in `modules/ai/agent-browser.nix`. The binary,
dashboard assets, and skill data are pinned together to upstream v0.39.1.
