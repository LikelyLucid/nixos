import importlib.util
from pathlib import Path
import unittest


module_path = Path(__file__).resolve().parents[1] / "modules/ai/agent-browser/session.py"
spec = importlib.util.spec_from_file_location("browser_session", module_path)
browser_session = importlib.util.module_from_spec(spec)
spec.loader.exec_module(browser_session)


class BrowserSessionTests(unittest.TestCase):
    def test_thread_is_stable_across_shell_commands(self):
        environment = {"CODEX_THREAD_ID": "thread-1"}
        self.assertEqual(
            browser_session.session_name(environment, "codex-123-456"),
            browser_session.session_name(environment, "codex-123-456"),
        )

    def test_threads_in_shared_agent_server_are_isolated(self):
        self.assertNotEqual(
            browser_session.session_name({"CODEX_THREAD_ID": "one"}, "codex-123-456"),
            browser_session.session_name({"CODEX_THREAD_ID": "two"}, "codex-123-456"),
        )

    def test_separate_agents_with_inherited_thread_are_isolated(self):
        environment = {"CODEX_THREAD_ID": "parent-thread"}
        self.assertNotEqual(
            browser_session.session_name(environment, "codex-123-456"),
            browser_session.session_name(environment, "codex-789-999"),
        )

    def test_explicit_child_identity_takes_precedence(self):
        parent = {"CODEX_THREAD_ID": "parent-thread"}
        child = {**parent, "AGENT_BROWSER_AGENT_ID": "child"}
        self.assertNotEqual(
            browser_session.session_name(parent, "codex-123-456"),
            browser_session.session_name(child, "codex-123-456"),
        )

    def test_session_name_is_short_and_safe(self):
        name = browser_session.session_name({"CODEX_THREAD_ID": "a/b $!" * 100}, "codex-1")
        self.assertRegex(name, r"^[a-zA-Z0-9_-]+$")
        self.assertLess(len(name), 48)

    def test_mcp_connections_under_one_agent_get_separate_sessions(self):
        for environment in [{}, {"CODEX_THREAD_ID": "shared-thread"}]:
            with self.subTest(environment=environment):
                first = browser_session.default_session(environment, "codex-123", ["mcp"], 100)
                second = browser_session.default_session(environment, "codex-123", ["mcp"], 200)
                self.assertNotEqual(first, second)
                self.assertEqual(
                    first,
                    browser_session.default_session(environment, "codex-123", ["mcp"], 100),
                )

    def test_regular_cli_commands_keep_the_thread_session(self):
        environment = {"CODEX_THREAD_ID": "thread"}
        self.assertEqual(
            browser_session.default_session(environment, "codex-123", ["open", "about:blank"], 100),
            browser_session.default_session(environment, "codex-123", ["snapshot"], 200),
        )
        self.assertEqual(
            browser_session.default_session(environment, "codex-123", ["fill", "@e1", "mcp"], 100),
            browser_session.session_name(environment, "codex-123"),
        )


if __name__ == "__main__":
    unittest.main()
