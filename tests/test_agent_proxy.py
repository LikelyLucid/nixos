"""Exercise discovery, credential boundaries and the actual client launch inputs."""

import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "agent_proxy", Path(__file__).parents[1] / "scripts/agent_proxy.py"
)
proxy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(proxy)


BASE_URL = "https://proxy.example.invalid/v1"


class DiscoveryTests(unittest.TestCase):
    def test_rejects_invalid_or_empty_catalogs(self):
        for payload in ({}, {"data": []}, {"data": [{}]}, {"data": [{"id": "bad\nmodel"}]}):
            with self.subTest(payload=payload), self.assertRaises(ValueError):
                proxy.model_ids(payload)

    def test_catalogs_keep_exact_ids_without_claiming_capabilities(self):
        ids = proxy.model_ids({"data": [{"id": "gpt-example"}, {"id": "claude-sonnet-example"},
                                          {"id": "gemini-example"}, {"id": "gpt-example"}]})
        generated = proxy.catalogs(ids, BASE_URL)
        self.assertEqual(len(generated["opencode.json"]["providers"]["cliproxy"]["models"]), 3)
        self.assertEqual(len(generated["pi/models.json"]["providers"]["cliproxy"]["models"]), 3)
        codex = generated["codex-models.json"]["models"]
        self.assertEqual([m["slug"] for m in codex], ["gpt-example"])
        self.assertNotIn("context_window", codex[0])
        self.assertEqual(codex[0]["supported_reasoning_levels"], [])
        self.assertEqual(generated["claude.json"]["model"], "claude-sonnet-example")

    def test_verified_default_and_current_pi_auth_syntax(self):
        generated = proxy.catalogs(["codex-auto-review", "gpt-6.1-sol", "gpt-image-2"], BASE_URL)
        self.assertEqual(generated["defaults.json"]["codex"], "gpt-6.1-sol")
        self.assertEqual(generated["opencode.json"]["model"], "cliproxy/gpt-6.1-sol")
        pi = generated["pi/models.json"]["providers"]["cliproxy"]
        self.assertEqual(pi["apiKey"], "$CLI_PROXY_API_KEY")
        self.assertEqual(pi["api"], "openai-responses")

    def test_all_discovered_opencode_models_use_chat_completions(self):
        ids = ["deepseek-v4.1-flash", "gpt-example", "new-provider/new-model"]
        generated = proxy.catalogs(ids, BASE_URL)
        provider = generated["opencode.json"]["providers"]["cliproxy"]
        self.assertEqual(provider["package"], "@opencode/ai/providers/openai-compatible")
        self.assertEqual(set(provider["models"]), set(ids))
        self.assertEqual(provider["settings"]["baseURL"], BASE_URL)
        self.assertTrue(all("package" not in model for model in provider["models"].values()))
        self.assertEqual(generated["pi/models.json"]["providers"]["cliproxy"]["api"], "openai-responses")

    def test_missing_codex_models_does_not_fabricate_one(self):
        self.assertIsNone(proxy.catalogs(["gemini-example"], BASE_URL)["defaults.json"]["codex"])


class OpenCodeAuthTests(unittest.TestCase):
    def test_rotates_only_saved_proxy_account_and_retains_identity(self):
        accounts = [
            {"id": "proxy-account", "integrationID": "cliproxy", "active": True,
             "value": {"type": "key", "key": "old"}},
            {"id": "other-account", "integrationID": "other", "value": {"type": "key", "key": "keep"}},
        ]
        with patch.object(proxy.subprocess, "run") as run:
            run.return_value.stdout = json.dumps(accounts).encode()
            proxy.sync_opencode_auth("/client", {}, "new")
            updated = json.loads(run.call_args.kwargs["input"])
            self.assertEqual(len(updated), 1)
            self.assertEqual(updated[0]["id"], "proxy-account")
            self.assertTrue(updated[0]["active"])
            self.assertEqual(updated[0]["value"]["key"], "new")
            self.assertNotIn("new", str(run.call_args.args))

    def test_failed_rotation_restores_previous_proxy_credential(self):
        account = {"id": "proxy-account", "integrationID": "cliproxy", "active": True,
                   "value": {"type": "key", "key": "old"}}
        exported = unittest.mock.Mock(stdout=json.dumps([account]).encode())
        with patch.object(proxy.subprocess, "run") as run:
            run.side_effect = [exported, unittest.mock.Mock(), OSError("import failed"), unittest.mock.Mock()]
            with self.assertRaises(OSError):
                proxy.sync_opencode_auth("/client", {}, "new")
            self.assertEqual(json.loads(run.call_args.kwargs["input"]), [account])

    def test_matching_proxy_key_leaves_saved_credentials_untouched(self):
        with patch.object(proxy.subprocess, "run") as run:
            run.return_value.stdout = json.dumps([{
                "integrationID": "cliproxy", "value": {"type": "key", "key": "same"}
            }]).encode()
            proxy.sync_opencode_auth("/client", {}, "same")
            self.assertEqual(run.call_count, 1)


class RuntimeTests(unittest.TestCase):
    def setUp(self):
        # Never let a developer shell redirect fixture writes to real secret files.
        environment = {key: value for key, value in os.environ.items() if key not in {
            "CLI_PROXY_API_KEY_FILE", "CLI_PROXY_BASE_URL_FILE", "CLI_PROXY_KEEP_AGENT_CONFIG", "CLI_PROXY_STATE_DIR",
            "OPENCODE_CONFIG_CONTENT", "OPENCODE_CONFIG", "PI_CODING_AGENT_DIR",
        }}
        self.environment_patch = patch.dict(os.environ, environment, clear=True)
        self.environment_patch.start()
        self.addCleanup(self.environment_patch.stop)
        self.temporary = tempfile.TemporaryDirectory()
        self.home = Path(self.temporary.name)
        self.home_patch = patch.object(Path, "home", return_value=self.home)
        self.home_patch.start()
        self.auth_patch = patch.object(proxy, "sync_opencode_auth")
        self.auth_patch.start()
        proxy.atomic_write(proxy.key_path(), "fixture-secret\n")
        proxy.atomic_write(self.home / ".config/agent-server/proxy-url", BASE_URL)
        self.state = self.home / ".local/state/agent-proxy"

    def tearDown(self):
        self.home_patch.stop()
        self.auth_patch.stop()
        self.temporary.cleanup()

    def response(self):
        response = unittest.mock.MagicMock()
        response.__enter__.return_value.read.return_value = json.dumps({"data": [
            {"id": "gpt-example"}, {"id": "claude-sonnet-example"}
        ]}).encode()
        return response

    def refresh(self):
        with patch.object(proxy.urllib.request, "build_opener") as opener:
            opener.return_value.open.return_value = self.response()
            proxy.refresh(self.state, "fixture-secret", BASE_URL, force=True)

    def test_key_permissions(self):
        self.assertEqual(proxy.key_path().stat().st_mode & 0o777, 0o600)
        proxy.key_path().chmod(0o644)
        with self.assertRaises(ValueError):
            proxy.read_key()

    def test_sops_runtime_path_is_used_instead_of_home_key(self):
        managed_key = self.home / "run/secrets/agent-proxy-api-key"
        proxy.atomic_write(managed_key, "sops-fixture-secret")
        managed_key.chmod(0o400)
        with patch.dict(os.environ, {"CLI_PROXY_API_KEY_FILE": str(managed_key)}):
            self.assertEqual(proxy.read_key(), "sops-fixture-secret")

    def test_sops_endpoint_requires_private_https_url(self):
        path = self.home / "managed-url"
        for value in ("http://proxy.invalid/v1", "https://key@proxy.invalid/v1", "https://proxy.invalid/v1?key=value"):
            proxy.atomic_write(path, value)
            with patch.dict(os.environ, {"CLI_PROXY_BASE_URL_FILE": str(path)}), self.assertRaises(ValueError):
                proxy.read_base_url()
        proxy.atomic_write(path, BASE_URL)
        with patch.dict(os.environ, {"CLI_PROXY_BASE_URL_FILE": str(path)}):
            self.assertEqual(proxy.read_base_url(), BASE_URL)

    def test_version_probe_does_not_require_credentials_or_network(self):
        proxy.key_path().unlink()
        with patch.object(proxy.os, "execve") as execute:
            with patch.object(proxy.sys, "argv", ["agent_proxy.py", "codex", "/fake/client", "--version"]):
                proxy.main()
            self.assertEqual(execute.call_args.args[1], ["/fake/client", "--version"])

    def test_successful_refresh_never_writes_key_to_catalog(self):
        self.refresh()
        self.assertTrue((self.state / "current").is_symlink())
        for path in (self.state / "current").rglob("*.json"):
            self.assertNotIn("fixture-secret", path.read_text())

    def test_refresh_replaces_recent_responses_catalog_and_discovers_new_models(self):
        self.refresh()
        previous = (self.state / "current").resolve()
        metadata = json.loads((previous / "metadata.json").read_text())
        metadata["schema_version"] = 2
        proxy.atomic_write(previous / "metadata.json", json.dumps(metadata))
        catalog = json.loads((previous / "opencode.json").read_text())
        catalog["providers"]["cliproxy"]["package"] = "@opencode/ai/providers/openai-compatible/responses"
        proxy.atomic_write(previous / "opencode.json", json.dumps(catalog))
        response = self.response()
        response.__enter__.return_value.read.return_value = json.dumps({"data": [
            {"id": "deepseek-v4.1-flash"}, {"id": "new-provider/new-model"}
        ]}).encode()
        with patch.object(proxy.urllib.request, "build_opener") as opener:
            opener.return_value.open.return_value = response
            proxy.refresh(self.state, "fixture-secret", BASE_URL)
            opener.return_value.open.assert_called_once()
        self.assertNotEqual((self.state / "current").resolve(), previous)
        provider = json.loads((self.state / "current/opencode.json").read_text())["providers"]["cliproxy"]
        self.assertEqual(provider["package"], "@opencode/ai/providers/openai-compatible")
        self.assertEqual(set(provider["models"]), {"deepseek-v4.1-flash", "new-provider/new-model"})

    def test_failed_refresh_preserves_exact_previous_generation(self):
        self.refresh()
        previous = (self.state / "current").resolve()
        with patch.object(proxy.urllib.request, "build_opener") as opener:
            opener.return_value.open.side_effect = OSError("offline")
            with self.assertRaises(OSError):
                proxy.refresh(self.state, "fixture-secret", BASE_URL, force=True)
        self.assertEqual((self.state / "current").resolve(), previous)

    def test_separate_opencode_state_preserves_existing_shared_catalog(self):
        self.refresh()
        previous = (self.state / "current").resolve()
        isolated = self.home / ".local/state/agent-proxy-opencode-chat"
        with patch.dict(os.environ, {"CLI_PROXY_STATE_DIR": str(isolated)}):
            with patch.object(proxy.urllib.request, "build_opener") as opener:
                opener.return_value.open.return_value = self.response()
                with patch.object(proxy.os, "execve") as execute:
                    with patch.object(proxy.sys, "argv", ["agent_proxy.py", "opencode", "/fake/client"]):
                        proxy.main()
        environment = execute.call_args.args[2]
        self.assertEqual(Path(environment["OPENCODE_CONFIG"]), (isolated / "current").resolve() / "opencode.json")
        self.assertEqual((self.state / "current").resolve(), previous)
        provider = json.loads(Path(environment["OPENCODE_CONFIG"]).read_text())["providers"]["cliproxy"]
        self.assertEqual(provider["package"], "@opencode/ai/providers/openai-compatible")

    def test_all_launchers_receive_runtime_key_and_discovered_config(self):
        self.refresh()
        for agent in ("codex", "claude", "opencode", "pi"):
            with self.subTest(agent=agent), patch.object(proxy.os, "execve") as execute:
                with patch.object(proxy.sys, "argv", ["agent_proxy.py", agent, "/fake/client", "--model", "fixture"]):
                    proxy.main()
                executable, arguments, environment = execute.call_args.args
                self.assertEqual(executable, "/fake/client")
                self.assertEqual(environment["CLI_PROXY_API_KEY"], "fixture-secret")
                self.assertNotIn("fixture-secret", str(arguments))
                if agent == "codex":
                    self.assertIn('model_provider="cliproxy"', arguments)
                elif agent == "claude":
                    self.assertEqual(environment["ANTHROPIC_AUTH_TOKEN"], "fixture-secret")
                    self.assertEqual(environment["ANTHROPIC_BASE_URL"], BASE_URL.removesuffix("/v1"))
                elif agent == "opencode":
                    self.assertTrue(Path(environment["OPENCODE_CONFIG"]).is_file())
                else:
                    self.assertTrue((Path(environment["PI_CODING_AGENT_DIR"]) / "models.json").is_file())

    def test_desktop_launch_preserves_pi_home_and_opencode_plugins(self):
        self.refresh()
        pi_home = self.home / "custom-pi"
        pi_home.mkdir()
        settings = pi_home / "settings.json"
        settings.write_text('{"packages":["npm:existing-plugin"]}')
        original = settings.read_bytes()
        config = {"plugin": ["existing-plugin"], "providers": {"existing": {"name": "Keep"}}}
        with patch.dict(os.environ, {
            "CLI_PROXY_KEEP_AGENT_CONFIG": "1", "PI_CODING_AGENT_DIR": str(pi_home),
            "OPENCODE_CONFIG": "/custom/opencode.jsonc",
            "OPENCODE_CONFIG_CONTENT": json.dumps(config),
        }):
            for agent in ("pi", "opencode", "codex"):
                with patch.object(proxy.os, "execve") as execute:
                    with patch.object(proxy.sys, "argv", ["agent_proxy.py", agent, "/fake/client"]):
                        proxy.main()
                    _, arguments, environment = execute.call_args.args
                    self.assertEqual(environment["PI_CODING_AGENT_DIR"], str(pi_home))
                    self.assertEqual(environment["OPENCODE_CONFIG"], "/custom/opencode.jsonc")
                    if agent == "pi":
                        self.assertIn("--extension", arguments)
                        extension = Path(arguments[arguments.index("--extension") + 1])
                        self.assertIn('pi.registerProvider("cliproxy"', extension.read_text())
                        self.assertNotIn("fixture-secret", extension.read_text())
                    elif agent == "opencode":
                        merged = json.loads(environment["OPENCODE_CONFIG_CONTENT"])
                        self.assertEqual(merged["plugin"], config["plugin"])
                        self.assertIn("existing", merged["providers"])
                        self.assertIn("cliproxy", merged["providers"])
        self.assertEqual(settings.read_bytes(), original)

    def test_server_agents_receive_cua_mcp_without_replacing_other_config(self):
        self.refresh()
        with patch.dict(os.environ, {"AGENT_CUA_COMMAND": "/nix/store/fixture/bin/cua"}):
            for agent in ("codex", "claude", "opencode"):
                with self.subTest(agent=agent), patch.object(proxy.os, "execve") as execute:
                    with patch.object(proxy.sys, "argv", ["agent_proxy.py", agent, "/fake/client"]):
                        proxy.main()
                    _, args, env = execute.call_args.args
                    if agent == "codex":
                        self.assertIn('mcp_servers.cua.command="/nix/store/fixture/bin/cua"', args)
                        self.assertIn('mcp_servers.cua.args=["mcp"]', args)
                    elif agent == "claude":
                        config = json.loads(Path(args[args.index("--mcp-config") + 1]).read_text())
                        self.assertEqual(config["mcpServers"]["cua"]["args"], ["mcp"])
                        self.assertNotIn("--strict-mcp-config", args)
                    else:
                        config = json.loads(Path(env["OPENCODE_CONFIG"]).read_text())
                        self.assertEqual(config["mcp"]["servers"]["cua"]["command"],
                                         ["/nix/store/fixture/bin/cua", "mcp"])
                        self.assertIn("cliproxy", config["providers"])

    def test_redirects_cannot_forward_bearer_token(self):
        with patch.object(proxy.urllib.request, "build_opener") as opener:
            opener.return_value.open.return_value = self.response()
            proxy.refresh(self.state, "fixture-secret", BASE_URL, force=True)
            handler = opener.call_args.args[0]()
            self.assertIsNone(handler.redirect_request(None, None, 302, "redirect", {}, "https://elsewhere"))


if __name__ == "__main__":
    unittest.main()
