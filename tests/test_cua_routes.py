"""Transport selection must not replay work or alter literal command data."""
import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "cua_routes", Path(__file__).resolve().parents[1] / "scripts/cua_routes.py")
routes = importlib.util.module_from_spec(spec)
spec.loader.exec_module(routes)
RELAY = "relay:example"
DIRECT = "direct:100.1.2.3:8212"
CONFIG = {RELAY: {"direct": DIRECT, "url": "http://100.1.2.3:8212"}}


class TransportTests(unittest.TestCase):
    def test_rechecks_before_each_action_and_recovers(self):
        availability = iter([True, False, True])
        router = routes.Router(CONFIG, probe=lambda _: next(availability))
        self.assertEqual([router.select(RELAY) for _ in range(3)],
                         [DIRECT, RELAY, DIRECT])

    def test_only_mcp_identity_changes(self):
        original = {"id": 7, "method": "tools/call", "params": {
            "name": "space_bash", "arguments": {"space": RELAY, "command": RELAY}}}
        message = routes.Router(CONFIG, probe=lambda _: True).request(original)
        self.assertEqual(message["params"]["arguments"],
                         {"space": DIRECT, "command": RELAY})
        self.assertEqual(original["params"]["arguments"]["space"], RELAY)

    def test_lifecycle_keeps_host_owner(self):
        router = routes.Router(CONFIG, probe=lambda _: self.fail("Must not probe"))
        for tool in routes.LIFECYCLE_TOOLS:
            request = {"method": "tools/call", "params": {
                "name": tool, "arguments": {"space": RELAY}}}
            self.assertEqual(router.request(request), request)
        self.assertEqual(router.cli(["spaces", "delete", RELAY]),
                         ["spaces", "delete", RELAY])

    def test_cli_keeps_command_and_prompt_literals(self):
        router = routes.Router(CONFIG, probe=lambda _: True)
        self.assertEqual(router.cli(["sb", "exec", RELAY, RELAY]),
                         ["sb", "exec", DIRECT, RELAY])
        self.assertEqual(router.cli(["agent", "run", RELAY, "codex", RELAY]),
                         ["agent", "run", DIRECT, "codex", RELAY])
        self.assertEqual(router.cli(["teleport", "push", "--app", "chrome", "-s", RELAY]),
                         ["teleport", "push", "--app", "chrome", "-s", DIRECT])

    def test_direct_alias_also_falls_back(self):
        router = routes.Router(CONFIG, probe=lambda _: False)
        self.assertEqual(router.select(DIRECT), RELAY)
        request = {"method": "tools/call", "params": {
            "name": "stop_space", "arguments": {"space": DIRECT}}}
        self.assertEqual(router.request(request)["params"]["arguments"]["space"], RELAY)

    def test_force_relay_and_unconfigured_machine(self):
        router = routes.Router(CONFIG, probe=lambda _: self.fail("Must not probe"))
        with patch.dict("os.environ", {"CUA_ROUTE_POLICY": "relay"}):
            self.assertEqual(router.select(RELAY), RELAY)
        self.assertEqual(router.select("local:other"), "local:other")


if __name__ == "__main__":
    unittest.main()
