import importlib.util
import json
from pathlib import Path
import sqlite3
import tempfile
import unittest


module_path = Path(__file__).resolve().parents[1] / "modules/ai/agent-browser/helium.py"
spec = importlib.util.spec_from_file_location("browser_helium", module_path)
browser_helium = importlib.util.module_from_spec(spec)
spec.loader.exec_module(browser_helium)


class HeliumProfileTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.source = self.root / "helium"
        self.profile = self.source / "Profile 1"
        self.profile.mkdir(parents=True)
        self.state = {"profile": {"info_cache": {
            "Default": {"name": "Personal"}, "Profile 1": {"name": "AGASSIST"},
        }}}
        (self.source / "Local State").write_text(json.dumps(self.state))
        (self.profile / "Preferences").write_text('{"profile":{"name":"AGASSIST"}}')
        (self.profile / "Local Storage").mkdir()
        (self.profile / "Local Storage" / "test").write_text("original")

    def destination(self, suffix):
        destination = self.root / f"agent-browser-chrome-{suffix}"
        destination.mkdir()
        return destination

    def test_copies_only_selected_profile_and_keeps_source_unchanged(self):
        (self.profile / "History").write_text("private history")
        (self.profile / "Login Data").write_text("saved passwords")
        (self.profile / "Cache").mkdir()
        (self.profile / "Cache" / "data").write_text("cached")
        (self.profile / "linked").symlink_to(self.profile / "History")
        destination = self.destination("one")
        args = browser_helium.launch_arguments([
            f"--user-data-dir={destination}", "--password-store=basic", "--use-mock-keychain",
        ], self.source, "agassist")
        self.assertEqual(args, [f"--user-data-dir={destination}", "--profile-directory=Default"])
        self.assertEqual(json.loads((self.source / "Local State").read_text()), self.state)
        copied = json.loads((destination / "Local State").read_text())
        self.assertEqual(copied["profile"]["last_used"], "Default")
        self.assertEqual(copied["profile"]["info_cache"], {"Default": {"name": "AGASSIST"}})
        for excluded in ["History", "Login Data", "Cache", "linked"]:
            self.assertFalse((destination / "Default" / excluded).exists())
        self.assertEqual(destination.stat().st_mode & 0o777, 0o700)
        retry = browser_helium.launch_arguments([
            f"--user-data-dir={destination}", "--password-store=basic", "--use-mock-keychain",
        ], self.source, "agassist")
        self.assertEqual(retry, args)

    def test_agents_receive_independent_storage(self):
        first, second = self.destination("one"), self.destination("two")
        for destination in [first, second]:
            browser_helium.copy_profile(self.source, destination, "AGASSIST")
        (first / "Default/Local Storage/test").write_text("changed")
        self.assertEqual((second / "Default/Local Storage/test").read_text(), "original")
        self.assertEqual((self.profile / "Local Storage/test").read_text(), "original")

    def test_cookie_backup_captures_live_wal(self):
        with sqlite3.connect(self.profile / "Cookies") as live:
            live.execute("PRAGMA journal_mode=WAL")
            live.execute("CREATE TABLE cookies (value TEXT)")
            live.execute("INSERT INTO cookies VALUES ('fixture')")
            live.commit()
            destination = self.destination("wal")
            browser_helium.copy_profile(self.source, destination, "AGASSIST")
            with sqlite3.connect(destination / "Default/Cookies") as copied:
                self.assertEqual(copied.execute("SELECT value FROM cookies").fetchall(), [("fixture",)])

    def test_clean_mode_and_explicit_profile_paths_are_not_seeded(self):
        for directory, name in [(self.destination("clean"), "none"), (self.root / "explicit", "AGASSIST")]:
            directory.mkdir(exist_ok=True)
            args = [f"--user-data-dir={directory}", "--password-store=basic"]
            self.assertEqual(browser_helium.launch_arguments(args, self.source, name), args)
            self.assertEqual(list(directory.iterdir()), [])

    def test_missing_profile_fails_instead_of_using_another_account(self):
        with self.assertRaises(ValueError):
            browser_helium.copy_profile(self.source, self.destination("missing"), "absent")


if __name__ == "__main__":
    unittest.main()
