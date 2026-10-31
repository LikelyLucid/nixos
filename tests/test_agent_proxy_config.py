#!/usr/bin/env python3
"""Native config reconciliation: all secrets, homes and network responses are fixtures."""
import copy
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import tomllib
import unittest
from unittest.mock import Mock, patch

script = Path(os.environ.get("AGENT_PROXY_CONFIG_SCRIPT", Path(__file__).resolve().parents[1] / "scripts/agent_proxy_config.py"))
module_spec = importlib.util.spec_from_file_location("agent_proxy_config", script)
proxy = importlib.util.module_from_spec(module_spec)
module_spec.loader.exec_module(proxy)

BASE = "https://fixture.invalid/v1"
KEY = "fixture-only-private-key"
CATALOGS = {
    "standard": {"data": [
        {"id": "gpt-6.1-sol", "owned_by": "openai", "context_length": 272000,
         "max_completion_tokens": 128000, "modalities": {"input": ["text", "image"]},
         "capabilities": {"reasoning": {"supported": True}, "tools": {"supported": True}}},
        {"id": "deepseek-fixture", "context_length": 1000000, "max_completion_tokens": 32000},
        {"id": "claude-sonnet-fixture", "context_length": 200000, "max_completion_tokens": 64000},
        {"id": "unknown-fixture"},
    ]},
    "native": {"models": [
        {"slug": "gpt-6.1-sol", "context_window": 500000, "max_context_window": 872000,
         "input_modalities": ["text", "image"]},
        {"slug": "deepseek-fixture", "context_window": 1000000},
        {"slug": "claude-sonnet-fixture", "context_window": 200000},
        {"slug": "unknown-fixture"},
    ]},
}


class ConfigTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.key = self.home / "sops/key"
        self.url = self.home / "sops/url"
        proxy.atomic_write(self.key, (KEY + "\n").encode())
        proxy.atomic_write(self.url, BASE.encode())
        self.spec = {"home": str(self.home), "key_file": str(self.key), "url_file": str(self.url),
                     "cat_executable": "/bin/cat", "codex_version": "0.165.0"}

    def write(self, path, value):
        data = value if isinstance(value, str) else json.dumps(value)
        proxy.atomic_write(self.home / path, data.encode())

    def planned(self):
        return {str(p.relative_to(self.home)): data for p, data, _ in proxy.configure(self.spec, BASE, CATALOGS)}

    def sync(self, catalogs=CATALOGS):
        with patch.object(proxy, "fetch_catalog", side_effect=[catalogs["standard"], catalogs["native"]]):
            proxy.reconcile(self.spec)

    def test_codex_native_auth_discovery_and_preserves_user_settings(self):
        self.write(".codex/config.toml", '# Keep this comment\nmodel = "gpt-6.1-sol"\nmodel_reasoning_effort = "high"\n[features]\nweb_search = true\n[mcp_servers.mine]\ncommand = "/my/tool"\n')
        raw = self.planned()[".codex/config.toml"].decode()
        doc = tomllib.loads(raw)
        provider = doc["model_providers"]["cliproxy"]
        self.assertEqual(provider["auth"]["args"], [str(proxy.credential_path(self.spec, BASE))])
        self.assertEqual(provider["model_catalog_url"], BASE + "/models?client_version=0.165.0")
        self.assertNotIn("env_key", provider)
        self.assertNotIn("model_catalog_json", doc)
        self.assertEqual(doc["model_reasoning_effort"], "high")
        self.assertEqual(doc["mcp_servers"]["mine"]["command"], "/my/tool")
        self.assertIn("# Keep this comment", raw)

    def test_migrates_only_owned_catalog_and_auth_fields(self):
        self.write(".codex/config.toml", 'model_catalog_json="/home/test/.local/state/agent-proxy/current/codex-models.json"\n[model_providers.cliproxy]\nenv_key="OLD_KEY"\nrequires_openai_auth=true\n')
        doc = tomllib.loads(self.planned()[".codex/config.toml"].decode())
        self.assertNotIn("model_catalog_json", doc)
        self.assertNotIn("requires_openai_auth", doc["model_providers"]["cliproxy"])
        self.write(".codex/config.toml", 'model_catalog_json="/my/independent.json"')
        with self.assertRaises(ValueError):
            self.planned()

    def test_native_limits_beat_stale_general_limits_without_global_500k(self):
        standard, models, oc = proxy.build_models(CATALOGS)
        self.assertEqual(standard["gpt-6.1-sol"]["context_length"], 272000)
        sol = next(m for m in models if m["id"] == "gpt-6.1-sol")
        self.assertEqual(sol["contextWindow"], 500000)
        self.assertEqual(sol["api"], "openai-responses")
        self.assertTrue(sol["reasoning"])
        self.assertEqual(sol["input"], ["text", "image"])
        self.assertEqual(oc["claude-sonnet-fixture"]["limit"]["context"], 200000)
        self.assertIs(oc["gpt-6.1-sol"]["capabilities"]["tools"], True)
        self.assertNotIn("unknown-fixture", oc)
        self.assertEqual(next(m for m in models if m["id"] == "deepseek-fixture")["api"], "openai-completions")

    def test_opencode_jsonc_preserves_plugins_mcp_other_providers_and_model(self):
        self.write(".config/opencode/opencode.jsonc", '''{
          // JSONC syntax stays supported
          "plugins": ["my-plugin"], "model":"cliproxy/deepseek-fixture",
          "mcp":{"mine":{"type":"local","command":["my-mcp"]}},
          "providers":{"other":{"name":"Keep"}, "cliproxy":{"settings":{"custom":42}}},
        }''')
        oc = json.loads(self.planned()[".config/opencode/opencode.jsonc"])
        self.assertEqual(oc["plugins"], ["my-plugin"])
        self.assertIn("mine", oc["mcp"])
        self.assertIn("other", oc["providers"])
        self.assertEqual(oc["model"], "cliproxy/deepseek-fixture")
        self.assertEqual(oc["providers"]["cliproxy"]["settings"]["custom"], 42)
        self.assertEqual(oc["providers"]["cliproxy"]["settings"]["apiKey"], "{file:" + str(proxy.credential_path(self.spec, BASE)) + "}")

    def test_pi_command_auth_overrides_only_proxy_saved_credentials(self):
        self.write(".pi/agent/auth.json", {"cliproxy": {"type":"api_key", "key":"old"}, "other":{"type":"oauth","access":"keep"}})
        docs = self.planned()
        pi = json.loads(docs[".pi/agent/models.json"])
        auth = json.loads(docs[".pi/agent/auth.json"])
        self.assertEqual(pi["providers"]["cliproxy"]["apiKey"], "!/bin/cat " + str(proxy.credential_path(self.spec, BASE)))
        self.assertEqual(auth["other"]["access"], "keep")
        self.assertEqual(auth["cliproxy"]["key"], pi["providers"]["cliproxy"]["apiKey"])
        self.assertNotIn(KEY, b"\n".join(docs.values()).decode())

    def test_pi_migration_reads_seed_and_does_not_write_checkout_or_settings_symlink(self):
        models = self.home / "pi-config/models.json"
        settings = self.home / "pi-config/settings.json"
        self.write("pi-config/models.json", {"providers":{"other":{"baseUrl":"https://keep.invalid"}}})
        self.write("pi-config/settings.json", {"defaultModel":"mine","extensions":["my-extension"]})
        self.spec["pi_models_seed"] = str(models)
        self.spec["pi_settings_seed"] = str(settings)
        (self.home / ".pi/agent").mkdir(parents=True)
        (self.home / ".pi/agent/settings.json").symlink_to(settings)
        self.sync()
        self.assertIn("other", json.loads((self.home / ".pi/agent/models.json").read_text())["providers"])
        self.assertEqual(json.loads(models.read_text()), {"providers":{"other":{"baseUrl":"https://keep.invalid"}}})
        self.assertTrue((self.home / ".pi/agent/settings.json").is_symlink())
        self.assertEqual(json.loads(settings.read_text())["defaultModel"], "mine")

    def test_claude_native_auth_and_gateway_preserve_unrelated_settings(self):
        self.write(".claude/settings.json", {"permissions":{"deny":["keep"]}, "env":{"MY_SETTING":"yes","ANTHROPIC_AUTH_TOKEN":"old"}})
        doc = json.loads(self.planned()[".claude/settings.json"])
        self.assertEqual(doc["apiKeyHelper"], "/bin/cat " + str(proxy.credential_path(self.spec, BASE)))
        self.assertEqual(doc["env"]["ANTHROPIC_BASE_URL"], "https://fixture.invalid")
        self.assertNotIn("ANTHROPIC_AUTH_TOKEN", doc["env"])
        self.assertEqual(doc["env"]["MY_SETTING"], "yes")
        self.assertEqual(doc["permissions"]["deny"], ["keep"])

    def test_claude_defaults_to_an_advertised_proxy_model_without_anthropic_routes(self):
        catalogs = copy.deepcopy(CATALOGS)
        catalogs["standard"]["data"] = [r for r in catalogs["standard"]["data"] if "claude" not in r["id"]]
        pending = proxy.configure(self.spec, BASE, catalogs)
        raw = next(data for path, data, old in pending if path == self.home / ".claude/settings.json")
        doc = json.loads(raw)
        self.assertEqual(doc["model"], "gpt-6.1-sol")
        self.assertEqual(doc["env"]["ANTHROPIC_DEFAULT_OPUS_MODEL"], "gpt-6.1-sol")
        self.assertNotIn("claude-opus-5-5", doc["availableModels"])

    def test_mcp_configuration_merges_without_losing_other_servers(self):
        self.spec["mcp_servers"] = {"cua":{"command":"/nix/tool","args":["mcp"]}}
        self.write(".claude.json", {"mcpServers":{"mine":{"command":"keep"}}, "projects":{"mine":{}}})
        docs = self.planned()
        self.assertIn("cua", tomllib.loads(docs[".codex/config.toml"].decode())["mcp_servers"])
        self.assertIn("cua", json.loads(docs[".config/opencode/opencode.jsonc"])["mcp"]["servers"])
        claude = json.loads(docs[".claude.json"])
        self.assertIn("mine", claude["mcpServers"])
        self.assertIn("projects", claude)

    def test_idempotence_private_files_and_rotation(self):
        self.sync()
        paths = [p for p, _, _ in proxy.configure(self.spec, BASE, CATALOGS)]
        before = {p: (p.read_bytes(), p.stat().st_mtime_ns) for p in paths}
        self.sync()
        for path, (raw, mtime) in before.items():
            self.assertEqual(path.read_bytes(), raw)
            self.assertEqual(path.stat().st_mtime_ns, mtime)
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        proxy.atomic_write(self.key, b"rotated-fixture-key")
        self.sync()
        for p in paths:
            self.assertNotIn(b"rotated-fixture-key", p.read_bytes())

    def test_same_endpoint_outage_preserves_cached_metadata(self):
        self.sync()
        with patch.object(proxy, "fetch_catalog", side_effect=OSError("offline")):
            proxy.reconcile(self.spec)
        sol = next(m for m in json.loads((self.home / ".pi/agent/models.json").read_text())["providers"]["cliproxy"]["models"] if m["id"] == "gpt-6.1-sol")
        self.assertEqual(sol["contextWindow"], 500000)

    def test_url_rotation_cannot_reuse_previous_endpoints_cache(self):
        self.sync()
        before = (self.home / ".codex/config.toml").read_bytes()
        proxy.atomic_write(self.url, b"https://different.invalid/v1")
        with patch.object(proxy, "fetch_catalog", side_effect=OSError("offline")), self.assertRaises(RuntimeError):
            proxy.reconcile(self.spec)
        self.assertEqual((self.home / ".codex/config.toml").read_bytes(), before)
        self.sync()
        self.assertIn("https://different.invalid/v1", (self.home / ".codex/config.toml").read_text())

    def test_url_and_key_rotation_do_not_leak_new_key_to_old_endpoint(self):
        self.sync()
        old_credential = proxy.credential_path(self.spec, BASE)
        proxy.atomic_write(self.key, b"new-endpoint-key")
        proxy.atomic_write(self.url, b"https://new.invalid/v1")
        with patch.object(proxy, "fetch_catalog", side_effect=OSError("offline")), self.assertRaises(RuntimeError):
            proxy.reconcile(self.spec)
        self.assertEqual(old_credential.read_text(), KEY)
        self.sync()
        self.assertEqual(old_credential.read_text(), KEY)
        new_credential = proxy.credential_path(self.spec, "https://new.invalid/v1")
        self.assertEqual(new_credential.read_text(), "new-endpoint-key")
        self.assertEqual(new_credential.stat().st_mode & 0o777, 0o600)
        self.assertIn(str(new_credential), (self.home / ".codex/config.toml").read_text())

    def test_no_cache_failure_writes_no_client_configuration(self):
        with patch.object(proxy, "fetch_catalog", side_effect=OSError("offline")), self.assertRaises(RuntimeError):
            proxy.reconcile(self.spec)
        self.assertFalse((self.home / ".codex/config.toml").exists())

    def test_malformed_client_configuration_aborts_before_any_writes(self):
        self.write(".claude/settings.json", "{bad-json")
        with self.assertRaises(ValueError):
            self.sync()
        self.assertFalse((self.home / ".codex/config.toml").exists())

    def test_corrupt_cache_is_repaired_from_a_valid_live_catalog(self):
        self.write(".local/state/agent-proxy-config/catalogs.json", "broken-json")
        self.sync()
        self.assertEqual(json.loads((self.home / ".local/state/agent-proxy-config/catalogs.json").read_text())["schema_version"], 1)

    def test_fetch_bounds_body_and_never_follows_redirects(self):
        response = Mock()
        response.__enter__ = Mock(return_value=response)
        response.__exit__ = Mock(return_value=False)
        response.read.return_value = b"x" * (proxy.MAX_CATALOG_BYTES + 1)
        opener = Mock()
        opener.open.return_value = response
        with patch.object(proxy.urllib.request, "build_opener", return_value=opener) as build:
            with self.assertRaises(ValueError):
                proxy.fetch_catalog(BASE + "/models", KEY)
            handler = build.call_args.args[0]
            self.assertIsNone(handler.redirect_request(None, None, 302, "redirect", {}, "https://untrusted.invalid"))
            request = opener.open.call_args.args[0]
            self.assertEqual(request.get_header("Authorization"), "Bearer " + KEY)
            self.assertEqual(request.get_header("User-agent"), "agent-server-model-discovery/1.0")

    def test_duplicate_and_invalid_limit_catalogs_rejected(self):
        for transform in [lambda p:p["standard"]["data"].append(p["standard"]["data"][0]),
                          lambda p:p["native"]["models"][0].update(context_window=True),
                          lambda p:p["native"]["models"][0].update(context_window=-1),
                          lambda p:p["native"]["models"][0].update(context_window=900000)]:
            value = copy.deepcopy(CATALOGS)
            transform(value)
            with self.assertRaises(ValueError):
                proxy.validate_catalogs(value)

    def test_private_secret_validation_and_url_validation(self):
        self.key.chmod(0o644)
        with self.assertRaises(ValueError):
            proxy.read_private(self.key)
        for url in ["http://fixture.invalid/v1", "https://user:pass@fixture.invalid/v1", "https://fixture.invalid/v1?key=secret", "https://fixture.invalid/#fragment"]:
            with self.assertRaises(ValueError):
                proxy.validate_url(url)

    def test_atomic_write_detects_concurrent_edit_and_does_not_follow_symlink(self):
        source = self.home / "source"
        proxy.atomic_write(source, b"original")
        link = self.home / "link"
        link.symlink_to(source)
        old = proxy.snapshot(link)
        proxy.atomic_write(link, b"managed", expected=old)
        self.assertFalse(link.is_symlink())
        self.assertEqual(source.read_bytes(), b"original")
        with self.assertRaises(RuntimeError):
            proxy.atomic_write(link, b"overwrite", expected=old)
        self.assertEqual(link.read_bytes(), b"managed")

    def test_failure_after_partial_commit_is_retryable(self):
        original = proxy.atomic_write
        calls = 0
        def fail_once(path, *args, **kwargs):
            nonlocal calls
            calls += 1
            if calls == 2:
                raise OSError("simulated crash")
            return original(path, *args, **kwargs)
        with patch.object(proxy, "atomic_write", side_effect=fail_once), self.assertRaises(OSError):
            self.sync()
        self.sync()
        self.assertTrue((self.home / ".claude/settings.json").exists())
        self.assertTrue((self.home / ".local/state/agent-proxy-config/catalogs.json").exists())

    def test_error_messages_do_not_echo_secrets_or_response_bodies(self):
        self.write("spec.json", self.spec)
        with patch.object(proxy.sys, "argv", ["sync", "--spec", str(self.home / "spec.json")]), patch.object(proxy, "fetch_catalog", side_effect=RuntimeError(KEY)), patch("sys.stderr") as stderr:
            self.assertEqual(proxy.main(), 1)
            self.assertNotIn(KEY, str(stderr.write.call_args_list))

    def test_failed_legacy_auth_migration_does_not_publish_new_client_urls(self):
        self.sync()
        prior = (self.home / ".codex/config.toml").read_bytes()
        self.spec["opencode_executable"] = "/native/opencode"
        proxy.atomic_write(self.url, b"https://replacement.invalid/v1")
        with patch.object(proxy, "drop_legacy_opencode_keys", side_effect=OSError("cannot retire account")), self.assertRaises(OSError):
            self.sync()
        self.assertEqual((self.home / ".codex/config.toml").read_bytes(), prior)

    def test_opencode_migration_removes_only_proxy_key_accounts(self):
        accounts = [
            {"id":"proxy", "integrationID":"cliproxy", "value":{"type":"key","key":KEY}},
            {"id":"other", "integrationID":"other", "value":{"type":"key","key":"keep"}},
            {"id":"oauth", "integrationID":"cliproxy", "value":{"type":"oauth"}},
        ]
        with patch.object(proxy.subprocess, "run") as run:
            run.return_value.stdout = json.dumps(accounts).encode()
            proxy.drop_legacy_opencode_keys("/native/opencode", self.home)
            self.assertEqual(run.call_count, 2)
            self.assertEqual(run.call_args.kwargs["env"]["HOME"], str(self.home))
            self.assertNotIn("CLI_PROXY_API_KEY", run.call_args.kwargs["env"])
            self.assertEqual(run.call_args.args[0], ["/native/opencode", "auth", "logout", "cliproxy", "proxy", "--standalone"])
            self.assertNotIn(KEY, str(run.call_args_list))

    def test_opencode_lost_ack_migration_reconciles_absence_on_retry(self):
        account = {"id":"proxy", "integrationID":"cliproxy", "value":{"type":"key","key":KEY}}
        with patch.object(proxy.subprocess, "run", side_effect=[Mock(stdout=json.dumps([account]).encode()), OSError("lost ack"), Mock(stdout=b"[]")]) as run:
            with self.assertRaises(OSError):
                proxy.drop_legacy_opencode_keys("/native/opencode", self.home)
            proxy.drop_legacy_opencode_keys("/native/opencode", self.home)
            self.assertEqual(run.call_count, 3)

    def test_rotation_notifies_opencode_without_rewriting_all_client_configs(self):
        self.sync()
        oc = self.home / ".config/opencode/opencode.jsonc"
        codex = self.home / ".codex/config.toml"
        before_oc, before_codex = oc.stat().st_ino, codex.stat().st_ino
        proxy.atomic_write(self.key, b"new-key-fixture")
        self.sync()
        self.assertNotEqual(oc.stat().st_ino, before_oc)
        self.assertEqual(codex.stat().st_ino, before_codex)



if __name__ == "__main__":
    unittest.main()
