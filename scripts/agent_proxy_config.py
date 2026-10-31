#!/usr/bin/env python3
"""Reconcile native agent configuration from private SOPS files, never launch agents."""

import argparse
import copy
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shlex
import stat
import subprocess
import sys
import tempfile
import urllib.parse
import urllib.request

import json5
import tomlkit

MAX_CATALOG_BYTES = 4 * 1024 * 1024


def read_private(path):
    path = Path(path)
    info = path.stat()
    if not stat.S_ISREG(info.st_mode) or info.st_mode & 0o077:
        raise ValueError("Secret must be a private regular file")
    value = path.read_text().strip()
    if not value or any(c.isspace() for c in value):
        raise ValueError("Secret must contain one nonempty value")
    return value


def validate_url(value):
    parsed = urllib.parse.urlsplit(value)
    if (parsed.scheme != "https" or not parsed.hostname or parsed.username
            or parsed.password or parsed.query or parsed.fragment
            or any(c.isspace() for c in value)):
        raise ValueError("Proxy URL must be an HTTPS base URL without credentials or query")
    return value.rstrip("/")


def atomic_write(path, content, expected=None):
    """Replace a file (not its symlink target), preserving concurrent edits on retry."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, name = tempfile.mkstemp(prefix=".agent-proxy-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        if expected is not None and snapshot(path) != expected:
            raise RuntimeError("Configuration changed concurrently; retry reconciliation")
        os.replace(name, path)
        directory = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        Path(name).unlink(missing_ok=True)


def snapshot(path):
    path = Path(path)
    link = os.readlink(path) if path.is_symlink() else None
    return (link, path.read_bytes() if path.exists() else None)


def read_document(path, kind="json", seed=None):
    old = snapshot(path)
    raw = old[1]
    if raw is None and seed and Path(seed).exists():
        raw = Path(seed).read_bytes()
    if kind == "toml":
        document = tomlkit.parse(raw.decode()) if raw else tomlkit.document()
    else:
        document = json5.loads(raw.decode(), allow_duplicate_keys=False) if raw else {}
    if not isinstance(document, dict):
        # TOMLDocument is a dict subclass.
        raise ValueError("Configuration must be an object")
    return document, old


def encode(document, kind="json"):
    if kind == "toml":
        return tomlkit.dumps(document).encode()
    return (json.dumps(document, indent=2, ensure_ascii=False) + "\n").encode()


def fetch_catalog(url, key):
    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, *args, **kwargs):
            return None

    request = urllib.request.Request(url, headers={
        "Authorization": "Bearer " + key, "Accept": "application/json",
        "User-Agent": "agent-server-model-discovery/1.0",
    })
    with urllib.request.build_opener(NoRedirect).open(request, timeout=25) as response:
        data = response.read(MAX_CATALOG_BYTES + 1)
    if len(data) > MAX_CATALOG_BYTES:
        raise ValueError("Model catalog exceeds size limit")
    return json.loads(data)


def positive_int(value):
    return type(value) is int and 0 < value <= 100_000_000


def index_models(payload, field, id_field):
    rows = payload.get(field) if isinstance(payload, dict) else None
    if not isinstance(rows, list) or not rows:
        raise ValueError("Model catalog must contain a nonempty list")
    indexed = {}
    for row in rows:
        name = row.get(id_field) if isinstance(row, dict) else None
        if (not isinstance(name, str) or not name or any(ord(c) < 32 for c in name)
                or name in indexed):
            raise ValueError("Invalid or duplicate model ID")
        for limit in ("context_length", "max_context_length", "max_completion_tokens",
                      "context_window", "max_context_window", "max_tokens"):
            if row.get(limit) is not None and not positive_int(row[limit]):
                raise ValueError("Invalid model token limit")
        if (positive_int(row.get("context_window")) and positive_int(row.get("max_context_window"))
                and row["context_window"] > row["max_context_window"]):
            raise ValueError("Model default exceeds its ceiling")
        indexed[name] = row
    return indexed


def validate_catalogs(catalogs):
    standard = index_models(catalogs["standard"], "data", "id")
    native = index_models(catalogs["native"], "models", "slug")
    if not set(standard).intersection(native):
        raise ValueError("Catalogs have no common models")
    return standard, native


def default_model(models, previous=None):
    if previous in models:
        return previous
    for name in ("gpt-6.1-sol", "gpt-5.3-codex"):
        if name in models:
            return name
    return sorted(models)[0]


def build_models(catalogs):
    standard, native = validate_catalogs(catalogs)
    pi_models, opencode_models = [], {}
    for name, row in sorted(standard.items()):
        codex = native.get(name, {})
        context = codex.get("context_window") or row.get("max_context_length") or row.get("context_length")
        output = row.get("max_completion_tokens") or codex.get("max_tokens")
        # Do not invent limits for unknown models: leave them unlisted until advertised.
        if not positive_int(context) or not positive_int(output):
            continue
        modalities = row.get("modalities", {}).get("input", [])
        modalities = codex.get("input_modalities") or modalities
        modalities = [v for v in modalities if v in ("text", "image")]
        if not modalities:
            modalities = ["text"]
        capabilities = copy.deepcopy(row.get("capabilities", {}))
        reasoning = capabilities.get("reasoning", {}).get("supported")
        if reasoning is None:
            reasoning = bool(row.get("reasoning", {}).get("supported_efforts"))
        # The discovery catalog and OpenCode config use different schemas:
        # tools.supported -> tools, cache_read -> cache.read.
        oc_capabilities = {"input": modalities}
        for field in ("temperature",):
            if type(capabilities.get(field)) is bool:
                oc_capabilities[field] = capabilities[field]
        tools = capabilities.get("tools", {}).get("supported")
        if type(tools) is bool:
            oc_capabilities["tools"] = tools
        oc_capabilities["reasoning"] = {"supported": bool(reasoning)}
        efforts = capabilities.get("reasoning", {}).get("effort")
        if reasoning and isinstance(efforts, list) and all(isinstance(e, str) for e in efforts):
            oc_capabilities["reasoning"]["effort"] = efforts
        cost = {k: v for k, v in row.get("cost", {}).items()
                if k in ("input", "output", "cache_read", "cache_write")
                and type(v) in (int, float) and v >= 0}
        pi_models.append({
            "id": name, "name": row.get("display_name") or name,
            "api": "openai-responses" if row.get("owned_by") in ("openai", "codex") else "openai-completions",
            "contextWindow": context, "maxTokens": output,
            "reasoning": bool(reasoning), "input": modalities,
            "cost": {"input": cost.get("input", 0), "output": cost.get("output", 0),
                     "cacheRead": cost.get("cache_read", 0), "cacheWrite": cost.get("cache_write", 0)},
        })
        opencode_models[name] = {
            "name": row.get("display_name") or name,
            "limit": {"context": context, "output": output},
            "capabilities": oc_capabilities,
            **({"cost": {**{k: v for k, v in cost.items() if k in ("input", "output")},
                          "cache": {k.removeprefix("cache_"): v for k, v in cost.items()
                                    if k in ("cache_read", "cache_write")}}} if cost else {}),
        }
    if not pi_models:
        raise ValueError("No models advertise usable limits")
    return standard, pi_models, opencode_models


def drop_legacy_opencode_keys(executable, home):
    """Retire only proxy API-key accounts that shadow the native SOPS file reference.

    Logout is idempotently reconciled by the next export after an interrupted or
    lost-ACK operation. No credential import or plaintext key duplication is needed.
    """
    command = [executable, "auth"]
    environment = {"HOME": str(home), "PATH": os.environ.get("PATH", os.defpath),
                   "XDG_CONFIG_HOME": str(home / ".config"), "XDG_DATA_HOME": str(home / ".local/share"),
                   "XDG_CACHE_HOME": str(home / ".cache"), "XDG_STATE_HOME": str(home / ".local/state")}
    kwargs = {"capture_output": True, "timeout": 30, "check": True,
              "env": environment, "cwd": home}
    exported = subprocess.run([*command, "export", "--standalone"], **kwargs)
    for account in json.loads(exported.stdout):
        if (account.get("integrationID", "").lower() == "cliproxy"
                and account.get("value", {}).get("type") == "key"):
            subprocess.run([*command, "logout", account["integrationID"], account["id"], "--standalone"], **kwargs)


def credential_path(spec, base):
    # Pin credentials to the endpoint. A URL+key rotation must not hand the new
    # endpoint's key to a still-running client using the old provider URL.
    endpoint = hashlib.sha256(base.encode()).hexdigest()
    return Path(spec["home"]) / ".local/state/agent-proxy-config/credentials" / endpoint


def configure(spec, base, catalogs):
    """Stage every merge before writing; manage only the cliproxy connection and defaults."""
    home = Path(spec["home"])
    cat = spec["cat_executable"]
    key_file = str(credential_path(spec, base))
    key_command = shlex.join([cat, key_file])
    standard, pi_models, opencode_models = build_models(catalogs)
    available = {m["id"] for m in pi_models}
    pending = []

    def load(relative, kind="json", seed=None):
        path = home / relative
        document, old = read_document(path, kind, seed)
        pending.append((path, document, old, kind))
        return document

    codex = load(".codex/config.toml", "toml")
    # Migrate only our obsolete catalog override; preserve independent user catalogs.
    local_catalog = codex.get("model_catalog_json")
    if local_catalog:
        if "/agent-proxy/" not in local_catalog:
            raise ValueError("Remove the independent Codex model_catalog_json before enabling proxy discovery")
        del codex["model_catalog_json"]
    codex["model_provider"] = "cliproxy"
    codex.setdefault("model", default_model(available))
    codex.setdefault("model_reasoning_effort", "medium")
    provider = codex.setdefault("model_providers", {}).setdefault("cliproxy", {})
    for field in ("env_key", "experimental_bearer_token", "requires_openai_auth"):
        provider.pop(field, None)
    provider.update({"name": "CLI proxy", "base_url": base, "wire_api": "responses",
                     "model_catalog_url": base + "/models?client_version=" + spec["codex_version"],
                     "auth": {"command": cat, "args": [key_file], "refresh_interval_ms": 30000}})
    for name, server in spec.get("mcp_servers", {}).items():
        codex.setdefault("mcp_servers", {})[name] = server

    opencode = load(".config/opencode/opencode.jsonc")
    opencode.setdefault("$schema", "https://opencode.ai/config.json")
    opencode.setdefault("policies", [
        {"action": "provider.use", "resource": "*", "effect": "deny"},
        {"action": "provider.use", "resource": "cliproxy", "effect": "allow"},
    ])
    provider = opencode.setdefault("providers", {}).setdefault("cliproxy", {})
    provider.update({"name": "CLI proxy", "package": "@opencode/ai/providers/openai-compatible",
                     "models": opencode_models})
    provider.pop("env", None)
    provider.setdefault("settings", {}).update({"baseURL": base, "apiKey": "{file:" + key_file + "}"})
    old_model = opencode.get("model", "")
    if not old_model or (old_model.startswith("cliproxy/") and old_model.removeprefix("cliproxy/") not in available):
        opencode["model"] = "cliproxy/" + default_model(available)
    for name, server in spec.get("mcp_servers", {}).items():
        opencode.setdefault("mcp", {}).setdefault("servers", {})[name] = {
            "type": "local", "command": [server["command"], *server.get("args", [])]}

    pi = load(".pi/agent/models.json", seed=spec.get("pi_models_seed"))
    provider = pi.setdefault("providers", {}).setdefault("cliproxy", {})
    provider.update({"baseUrl": base, "api": "openai-completions", "apiKey": "!" + key_command,
                     "models": pi_models})
    # Stored credentials take precedence over models.json; store a command, never the key.
    auth = load(".pi/agent/auth.json")
    auth["cliproxy"] = {"type": "api_key", "key": "!" + key_command}
    settings = load(".pi/agent/settings.json", seed=spec.get("pi_settings_seed"))
    settings.setdefault("defaultProvider", "cliproxy")
    if settings["defaultProvider"] == "cliproxy":
        settings["defaultModel"] = default_model(available, settings.get("defaultModel"))
    settings.setdefault("defaultThinkingLevel", "medium")
    # Preserve the external settings symlink: these defaults belong in a writable local file.
    # Pi settings remain user-owned; only initialize them if absent.
    if pending[-1][2][1] is not None:
        pending.pop()

    claude = load(".claude/settings.json")
    claude["apiKeyHelper"] = key_command
    claude_env = claude.setdefault("env", {})
    for field in ("ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_API_KEY", "CLAUDE_CODE_OAUTH_TOKEN"):
        claude_env.pop(field, None)
    claude_env.update({"ANTHROPIC_BASE_URL": base.removesuffix("/v1"),
                       "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY": "1",
                       "CLAUDE_CODE_API_KEY_HELPER_TTL_MS": "30000"})
    claude_models = sorted(name for name in standard if "claude" in name.lower())
    # Claude Code is a client, not a requirement for Anthropic-only inference.
    # If this gateway advertises no Claude models, use its available default
    # through /v1/messages instead of the CLI's unsupported built-in Opus ID.
    choices = claude_models or sorted(available)
    fallback = next((n for n in claude_models if "sonnet" in n), default_model(available))
    if claude.get("model") not in choices and claude.get("model") not in ("opus", "sonnet", "haiku"):
        claude["model"] = fallback
    claude["availableModels"] = choices
    for family in ("opus", "sonnet", "haiku"):
        matches = [name for name in claude_models if family in name.lower()]
        claude_env["ANTHROPIC_DEFAULT_" + family.upper() + "_MODEL"] = matches[-1] if matches else fallback
    if spec.get("mcp_servers"):
        mcp = load(".claude.json")
        mcp.setdefault("mcpServers", {}).update(spec["mcp_servers"])
    # Render now so malformed files/types fail before any existing configuration changes.
    return [(path, encode(document, kind), old) for path, document, old, kind in pending]


def reconcile(spec):
    home = Path(spec["home"])
    state = home / ".local/state/agent-proxy-config"
    state.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (state / "sync.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        key = read_private(spec["key_file"])
        base = validate_url(read_private(spec["url_file"]))
        cache_file = state / "catalogs.json"
        try:
            previous_cache = json.loads(cache_file.read_text()) if cache_file.exists() else {}
            if not isinstance(previous_cache, dict):
                previous_cache = {}
        except (ValueError, UnicodeError):
            previous_cache = {}
        key_digest = hashlib.sha256(key.encode()).hexdigest()
        key_changed = previous_cache.get("key_digest") != key_digest
        try:
            catalogs = {
                "standard": fetch_catalog(base + "/models", key),
                "native": fetch_catalog(base + "/models?client_version=" + spec["codex_version"], key),
            }
            validate_catalogs(catalogs)
        except Exception:
            cache = previous_cache
            if cache.get("base_url") != base or cache.get("schema_version") != 1:
                raise RuntimeError("Proxy discovery failed; no valid catalog for this endpoint") from None
            catalogs = cache["catalogs"]
            validate_catalogs(catalogs)
            print("Proxy discovery unavailable; retaining this endpoint's last valid model metadata", file=sys.stderr)
        pending = configure(spec, base, catalogs)
        backups = state / "backups"
        # Optimistically guard every observed file before starting the multi-file reconciliation.
        if any(snapshot(path) != old for path, _, old in pending):
            raise RuntimeError("Configuration changed concurrently; retry reconciliation")
        key_target = credential_path(spec, base)
        if not key_target.exists() or key_target.read_text() != key:
            atomic_write(key_target, key.encode())
        # Retire legacy shadow credentials before publishing a possibly new URL.
        # Failure leaves the prior client files in place and can be retried.
        if spec.get("opencode_executable"):
            drop_legacy_opencode_keys(spec["opencode_executable"], home)
        for path, data, old in pending:
            # Trigger OpenCode's native config watcher on rotation even though its
            # {file:...} reference has not changed. Other clients reread the helper.
            force_reload = key_changed and path == home / ".config/opencode/opencode.jsonc"
            if old[1] == data and old[0] is None and not force_reload:
                continue
            if old[1] is not None:
                digest = hashlib.sha256(str(path).encode() + old[1]).hexdigest()
                backup = backups / digest
                if not backup.exists():
                    atomic_write(backup, old[1])
            atomic_write(path, data, expected=old)
        atomic_write(cache_file, encode({"schema_version": 1, "base_url": base, "key_digest": key_digest, "catalogs": catalogs}))
        print("Native agent proxy configuration synchronized (credentials remain in SOPS/native credential storage)")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--spec", required=True, type=Path)
    args = parser.parse_args()
    os.umask(0o077)
    try:
        reconcile(json.loads(args.spec.read_text()))
    except Exception as error:
        # Never log provider bodies, auth exports, secret values, or subprocess stderr.
        print(f"Agent proxy configuration failed ({type(error).__name__}); existing files are preserved or retryable. "
              "Check private SOPS files, configuration syntax and proxy connectivity.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
