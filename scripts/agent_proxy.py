#!/usr/bin/env python3
"""Discover the private proxy catalog and launch agents with runtime credentials."""

import fcntl
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.request
import urllib.parse



def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, temporary = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(content)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def key_path():
    configured = os.environ.get("CLI_PROXY_API_KEY_FILE")
    return Path(configured) if configured else Path.home() / ".config/agent-server/proxy-key"


def read_key():
    path = key_path()
    if path.stat().st_mode & 0o077:
        raise ValueError(f"{path} must be private: chmod 600 {path}")
    key = path.read_text().strip()
    if not key or any(character.isspace() for character in key):
        raise ValueError("Proxy key is empty or contains whitespace")
    return key


def read_base_url():
    configured = os.environ.get("CLI_PROXY_BASE_URL_FILE")
    path = Path(configured) if configured else Path.home() / ".config/agent-server/proxy-url"
    if path.stat().st_mode & 0o077:
        raise ValueError("Proxy endpoint file must be private")
    base_url = path.read_text().strip().rstrip("/")
    parsed = urllib.parse.urlsplit(base_url)
    if (parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password
            or parsed.query or parsed.fragment or any(c.isspace() for c in base_url)):
        raise ValueError("Proxy endpoint must be an HTTPS API URL")
    return base_url


def model_ids(payload):
    data = payload.get("data")
    if not isinstance(data, list) or not data:
        raise ValueError("Proxy returned an empty or invalid model catalog")
    ids = []
    for entry in data:
        model = entry.get("id") if isinstance(entry, dict) else None
        if not isinstance(model, str) or not model or any(ord(c) < 32 for c in model):
            raise ValueError("Proxy returned an invalid model ID")
        ids.append(model)
    return sorted(set(ids))


def catalogs(ids, base_url):
    # /models supplies IDs, not capabilities. Do not invent context limits,
    # prices, image support, or reasoning levels from model names.
    codex_ids = [m for m in ids if any(x in m.lower() for x in ("gpt", "codex"))
                 or m.lower().split("/")[-1].startswith(("o1", "o3", "o4"))]
    claude_ids = [m for m in ids if "claude" in m.lower()]
    # Prefer the model verified on this server when it is still advertised.
    codex_default = next((m for m in ("gpt-6.1-sol", "gpt-5.3-codex") if m in codex_ids),
                         next((m for m in codex_ids if "image" not in m and m != "codex-auto-review"), None))
    models = [dict(
        slug=model, display_name=model, description="CLI proxy model",
        supported_reasoning_levels=[], shell_type="unified_exec",
        visibility="list", supported_in_api=True, priority=index,
        availability_nux=None, upgrade=None, base_instructions="You are a coding assistant.",
        support_verbosity=False, default_verbosity=None, apply_patch_tool_type=None,
        truncation_policy={"mode": "bytes", "limit": 10000},
        experimental_supported_tools=[], input_modalities=["text"],
    ) for index, model in enumerate(codex_ids)]
    pi_models = [{"id": model, "name": model} for model in ids]
    claude_env = {
        "ANTHROPIC_BASE_URL": base_url.removesuffix("/v1"),
        "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY": "1",
    }
    for family in ("OPUS", "SONNET", "HAIKU"):
        matches = [m for m in claude_ids if family.lower() in m.lower()]
        if matches:
            claude_env[f"ANTHROPIC_DEFAULT_{family}_MODEL"] = matches[-1]
    claude = {"env": claude_env}
    if claude_ids:
        claude["model"] = claude_env.get("ANTHROPIC_DEFAULT_SONNET_MODEL", claude_ids[0])
        claude["availableModels"] = claude_ids
    return {
        "metadata.json": {"base_url": base_url, "schema_version": 3},
        "models.json": {"data": [{"id": m} for m in ids]},
        "codex-models.json": {"models": models},
        "defaults.json": {"codex": codex_default},
        "claude.json": claude,
        "opencode.json": {
            "$schema": "https://opencode.ai/config.json",
            "policies": [
                {"action": "provider.use", "resource": "*", "effect": "deny"},
                {"action": "provider.use", "resource": "cliproxy", "effect": "allow"},
            ],
            **({"model": "cliproxy/" + codex_default} if codex_default else {}),
            "providers": {"cliproxy": {
                "package": "@opencode/ai/providers/openai-compatible", "name": "CLI proxy",
                "env": ["CLI_PROXY_API_KEY"],
                "settings": {"baseURL": base_url, "apiKey": "{env:CLI_PROXY_API_KEY}"},
                "models": {model: {"name": model} for model in ids},
            }},
        },
        "pi/models.json": {"providers": {"cliproxy": {
            "baseUrl": base_url, "api": "openai-responses",
            "apiKey": "$CLI_PROXY_API_KEY", "models": pi_models,
        }}},
    }


def refresh(state, key, base_url, force=False):
    state.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (state / "refresh.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        current = state / "current"
        if (not force and current.exists() and time.time() - current.stat().st_mtime < 900
                and json.loads((current / "metadata.json").read_text()) == {
                    "base_url": base_url, "schema_version": 3}):
            return
        request = urllib.request.Request(base_url + "/models", headers={
            "Authorization": "Bearer " + key, "Accept": "application/json",
            "User-Agent": "agent-server-model-discovery/1.0",
        })
        # Never forward credentials to a redirect destination.
        class NoRedirect(urllib.request.HTTPRedirectHandler):
            def redirect_request(self, req, fp, code, msg, headers, newurl):
                return None
        with urllib.request.build_opener(NoRedirect).open(request, timeout=30) as response:
            payload = json.loads(response.read(4 * 1024 * 1024))
        generated = catalogs(model_ids(payload), base_url)
        generation = Path(tempfile.mkdtemp(prefix="catalog-", dir=state))
        try:
            for name, value in generated.items():
                atomic_write(generation / name, json.dumps(value, indent=2) + "\n")
            temporary = state / "next"
            temporary.unlink(missing_ok=True)
            temporary.symlink_to(generation.name, target_is_directory=True)
            os.replace(temporary, current)
        except BaseException:
            shutil.rmtree(generation)
            raise
        # Keep previous generations for already-running clients.
        print(f"Discovered {len(generated['models.json']['data'])} proxy models", file=sys.stderr)


def sync_opencode_auth(executable, environment, key):
    # V2 saved accounts take precedence over provider environment credentials.
    # Use the public CLI so account IDs and unrelated integrations stay intact.
    exported = subprocess.run([executable, "auth", "export", "--standalone"],
                              env=environment, capture_output=True, timeout=30, check=True)
    for account in json.loads(exported.stdout):
        if (account.get("integrationID", "").lower() == "cliproxy"
                and account.get("value", {}).get("type") == "key"
                and account["value"].get("key") != key):
            original = json.dumps([account]).encode()
            account["value"]["key"] = key
            # Import deliberately skips existing IDs. Replace only this account,
            # restoring the old credential if the new import fails.
            subprocess.run([executable, "auth", "logout", account["integrationID"],
                            account["id"], "--standalone"], env=environment,
                           capture_output=True, timeout=30, check=True)
            try:
                subprocess.run([executable, "auth", "import", "--standalone"],
                               input=json.dumps([account]).encode(), env=environment,
                               capture_output=True, timeout=30, check=True)
            except Exception:
                subprocess.run([executable, "auth", "import", "--standalone"],
                               input=original, env=environment, capture_output=True,
                               timeout=30, check=True)
                raise


def main():
    os.umask(0o077)
    command, *arguments = sys.argv[1:]
    if command in {"codex", "claude", "opencode", "pi"} and arguments[1:] in (
        ["--version"], ["-v"], ["--help"], ["-h"],
    ):
        # T3 probes installed clients without needing a working model service.
        os.execve(arguments[0], arguments, os.environ.copy())
        return
    key = read_key()
    base_url = read_base_url()
    # Allow independently upgraded launchers to avoid rewriting each other's catalogs.
    state = Path(os.environ.get("CLI_PROXY_STATE_DIR", str(Path.home() / ".local/state/agent-proxy")))
    if command == "refresh":
        refresh(state, key, base_url, force=True)
        return
    try:
        refresh(state, key, base_url)
    except Exception:
        if (not (state / "current").exists()
                or json.loads((state / "current/metadata.json").read_text())["base_url"] != base_url):
            raise
        print("Proxy discovery unavailable; using the previous catalog", file=sys.stderr)
    current = (state / "current").resolve()
    environment = os.environ.copy()
    environment["CLI_PROXY_API_KEY"] = key
    executable = arguments.pop(0)
    mcp_servers = {}
    for name, variable, args in (
        ("cua", "AGENT_CUA_COMMAND", ["mcp"]),
        ("agent-browser", "AGENT_BROWSER_COMMAND", ["mcp", "--tools", "all"]),
    ):
        if environment.get(variable):
            mcp_servers[name] = {"command": environment[variable], "args": args}
    if command == "codex":
        default = json.loads((current / "defaults.json").read_text())["codex"]
        if not default:
            raise ValueError("Proxy catalog contains no recognized Codex/Responses model IDs")
        for name, server in mcp_servers.items():
            arguments = ["-c", f"mcp_servers.{name}.command={json.dumps(server['command'])}",
                         "-c", f"mcp_servers.{name}.args={json.dumps(server['args'])}", *arguments]
        arguments = ["-c", 'model_provider="cliproxy"', "-c", f"model={json.dumps(default)}",
                     "-c", f"model_catalog_json={json.dumps(str(current / 'codex-models.json'))}",
                     "-c", 'model_providers.cliproxy.name="CLI proxy"',
                     "-c", f"model_providers.cliproxy.base_url={json.dumps(base_url)}",
                     "-c", 'model_providers.cliproxy.env_key="CLI_PROXY_API_KEY"',
                     "-c", 'model_providers.cliproxy.wire_api="responses"', *arguments]
    elif command == "claude":
        environment["ANTHROPIC_AUTH_TOKEN"] = key
        environment.pop("ANTHROPIC_API_KEY", None)
        environment.pop("CLAUDE_CODE_OAUTH_TOKEN", None)
        environment.update(json.loads((current / "claude.json").read_text())["env"])
        arguments = ["--settings", str(current / "claude.json"), *arguments]
        if mcp_servers:
            mcp_config = state / "claude-agent-mcp.json"
            atomic_write(mcp_config, json.dumps({"mcpServers": mcp_servers}))
            arguments = ["--mcp-config", str(mcp_config), *arguments]
    elif command == "opencode":
        generated = json.loads((current / "opencode.json").read_text())
        if mcp_servers:
            generated["mcp"] = {"servers": {
                name: {"type": "local", "command": [server["command"], *server["args"]]}
                for name, server in mcp_servers.items()
            }}
        if environment.get("CLI_PROXY_KEEP_AGENT_CONFIG") == "1":
            # Inline overrides merge above global/project config, including plugins.
            config = json.loads(environment.get("OPENCODE_CONFIG_CONTENT", "{}"))
            config.setdefault("providers", {}).update(generated.pop("providers"))
            if "mcp" in generated:
                config.setdefault("mcp", {}).setdefault("servers", {}).update(generated.pop("mcp")["servers"])
            config.update(generated)
            environment["OPENCODE_CONFIG_CONTENT"] = json.dumps(config)
        elif mcp_servers:
            mcp_config = state / "opencode-agent-mcp.json"
            atomic_write(mcp_config, json.dumps(generated))
            environment["OPENCODE_CONFIG"] = str(mcp_config)
        else:
            environment["OPENCODE_CONFIG"] = str(current / "opencode.json")
        with (state / "opencode-auth.lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            sync_opencode_auth(executable, environment, key)
    elif command == "pi":
        if environment.get("CLI_PROXY_KEEP_AGENT_CONFIG") == "1":
            # Add one provider without moving Pi's settings, extensions or sessions.
            extension = state / "cliproxy-provider.mjs"
            provider = json.loads((current / "pi/models.json").read_text())["providers"]["cliproxy"]
            # Extension registration requires full model fields. Match Pi's own
            # models.json fallback limits; these are client limits, not discovered
            # capabilities or a claim about upstream pricing.
            for model in provider["models"]:
                model.update(reasoning=False, input=["text"], contextWindow=128000,
                             maxTokens=16384, cost=dict(input=0, output=0, cacheRead=0, cacheWrite=0))
            atomic_write(extension, "export default function(pi) { pi.registerProvider(\"cliproxy\", "
                         + json.dumps(provider) + "); }\n")
            arguments = ["--extension", str(extension), *arguments]
        else:
            # Keep sessions/auth/extensions writable and stable across catalog swaps.
            pi_home = state / "pi"
            pi_home.mkdir(exist_ok=True, mode=0o700)
            models = pi_home / "models.json"
            if not models.is_symlink():
                models.symlink_to(state / "current/pi/models.json")
            environment["PI_CODING_AGENT_DIR"] = str(pi_home)
        default = json.loads((current / "defaults.json").read_text())["codex"]
        arguments = ["--provider", "cliproxy", *(["--model", default] if default else []), *arguments]
    else:
        raise ValueError("Unknown agent")
    os.execve(executable, [executable, *arguments], environment)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # Avoid printing response bodies, request headers or the key.
        print(f"Agent proxy setup failed ({type(error).__name__}). "
              "Check the private key, proxy connectivity and /models response.", file=sys.stderr)
        sys.exit(1)
