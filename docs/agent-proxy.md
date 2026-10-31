# Declarative agent proxy configuration

`artsxps` and the `agent-server` profile install the native Codex, OpenCode v2,
Pi and Claude Code packages. There are **no proxy launch wrappers**, injected
per-launch model catalogs, API keys in shell initialization, or alternate agent
homes. The Codex Desktop app also uses the native Codex package.

## One source for the connection

Edit the existing encrypted `secrets/agent-server.yaml` with SOPS:

- `cli-proxy-base-url`: an HTTPS OpenAI-compatible base URL ending in `/v1`.
- `cli-proxy-api-key`: its API key.

Both values are decrypted to owner-only SOPS files under `/run/secrets`. Do not
put the decrypted values into Nix source, the store, session variables, or Git.
The service materializes an owner-only runtime credential snapshot per endpoint
under `~/.local/state/agent-proxy-config/credentials/`. Clients reference that
snapshot, not a global environment key. This prevents a URL+key rotation from
sending the new endpoint's key to an old still-running provider connection.
The regular NixOS secret installation/activation process applies rotations; both
secrets restart `agent-proxy-config.service`, not T3 or running agents.

The system service runs as `lucid` after Home Manager activation. Its timer also
refreshes model metadata every 15 minutes. Client startup does not wait for this
service or run a discovery script. The first successful setup needs connectivity;
after that, a network outage retains the last valid catalog for the same URL.
Changing to a new URL cannot reuse the old endpoint's model catalog.

## Native client integration

- **Codex**: its native `model_catalog_url` points at
  `/models?client_version=<installed Codex version>`. Codex downloads and caches
  the full native catalog itself. A native `auth.command` reads the endpoint-pinned runtime key file
  using `cat`, with a 30-second refresh interval. No `env_key` or generated
  `model_catalog_json` override is needed.
- **OpenCode v2**: a native provider uses the OpenAI-compatible Chat Completions
  runtime and a native `{file:...}` reference to that runtime snapshot. The service maps model
  capabilities and limits into OpenCode's config schema. Legacy saved **cliproxy
  API-key** accounts are retired because they shadow the file reference; other
  providers and OAuth accounts are untouched. Key rotation atomically replaces
  the config file even when its text is unchanged so the native watcher reloads
  the reference. Existing provider policies and selected available models remain.
- **Pi**: native `models.json` and the cliproxy entry in `auth.json` use a `!cat`
  credential command. OpenAI/Codex models use Responses; other proxy chat models
  use Chat Completions. Existing settings, extensions, sessions and other
  providers remain. Only `models.json` moves out of the pi-config symlink set;
  the first migration seeds other model providers from the existing checkout.
- **Claude Code**: native `apiKeyHelper`, `ANTHROPIC_BASE_URL`, gateway discovery,
  and advertised Claude model aliases are written into its settings. Its key
  helper refresh interval is 30 seconds. The service does not export a global
  Anthropic credential. When the gateway advertises no Anthropic models, Claude
  Code defaults to the available proxy model (Sol when advertised), with its
  Opus/Sonnet/Haiku aliases mapped to available routes. This is Claude Code
  running a proxy-served model, not a claim of access to an Anthropic model.

Pi/OpenCode use the Codex-native default context window when present and the
standard catalog's advertised limits otherwise. Thus Sol's native 500,000-token
default is retained instead of the general list's older 272,000 value. Unknown
models without advertised context/output limits are not assigned invented
capacities. The refresh does not impose 500k on genuinely smaller models or
change the server's advertised upper bounds.

Configuration merges preserve unrelated settings and Codex TOML comments.
OpenCode JSONC is accepted and rewritten as formatted JSON (JSONC comments are
not retained). New runtime files and backups are private. Original contents are
backed up under `~/.local/state/agent-proxy-config/backups/` before replacement;
symlink targets, including the pi-config checkout, are not modified. Observed
file contents are checked before replacement to detect concurrent changes.
Each file replacement is atomic; the complete multi-file reconciliation is not.
An interrupted run is safe to retry and is retried by systemd.

The known old imperative `opencode-cliproxy-chat` profile package is removed by a
narrow Home Manager migration. No other imperative profile entries are removed.

## Inspect or retry

```sh
systemctl status agent-proxy-config.service
systemctl list-timers agent-proxy-config.timer
journalctl -u agent-proxy-config.service -n 30
sudo systemctl restart agent-proxy-config.service
```

Diagnostics intentionally omit keys, provider response bodies, and credential
exports. Restart a client or its T3 app-server when changing endpoints if it does
not reload provider settings automatically; do not interrupt active sessions just
to apply a rotation. Codex/Pi/Claude use their own credential-refresh semantics.
No proxy-server rebuild is needed to consume its existing native model catalog.

## Verification

```sh
nix build .#checks.x86_64-linux.agent-proxy-config
nix build '.#nixosConfigurations.artsxps.config.systemd.units."agent-proxy-config.service".unit'
```

Tests use temporary homes, fixture secrets, and mocked network/credential APIs.
They cover native metadata mapping, rotation, account migration, preservation,
private permissions, redirects, malformed catalogs, URL-scoped last-known-good
recovery, concurrent edits and interrupted reconciliation. Before activation,
build the full target system as required by `AGENTS.md`. Do not claim a switch
succeeded merely because the focused service and client tests passed.
