"""Check bootstrap versus existing-service reconciliation without touching systemd."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).parents[1] / "scripts/bootstrap-t3-service.sh"


class BootstrapTests(unittest.TestCase):
    def run_bootstrap(self, installed=False, fail_update=False):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        home = Path(temporary.name)
        binary = home / "bin"
        binary.mkdir()
        log = home / "commands"
        unit = home / ".config/systemd/user/t3code.service"
        if installed:
            unit.parent.mkdir(parents=True)
            unit.write_text("existing-newer-runtime")
            marker = home / ".t3/runtime/.nixos-service-bootstrapped"
            marker.parent.mkdir(parents=True)
            marker.touch()
        systemctl = binary / "systemctl"
        systemctl.write_text('#!/bin/sh\nprintf "systemctl %s\\n" "$*" >> "$TEST_COMMAND_LOG"\n')
        systemctl.chmod(0o755)
        cli = binary / "bootstrap-t3"
        cli.write_text('''#!/bin/sh
printf 't3 %s\n' "$*" >> "$TEST_COMMAND_LOG"
if [ "$1" = update ]; then
  if [ "$TEST_FAIL_UPDATE" = 1 ]; then exit 7; fi
  exit 0
fi
mkdir -p "$HOME/.config/systemd/user" "$HOME/.t3/runtime/versions/0.1.3"
printf 'managed-runtime' > "$HOME/.config/systemd/user/t3code.service"
printf '#!/bin/sh\n' > "$HOME/.t3/runtime/versions/0.1.3/t3"
chmod +x "$HOME/.t3/runtime/versions/0.1.3/t3"
''')
        cli.chmod(0o755)
        env = dict(os.environ, HOME=str(home), PATH=str(binary) + os.pathsep + os.environ["PATH"],
                   T3_BOOTSTRAP_CLI=str(cli), T3_BOOTSTRAP_VERSION="0.1.3", TEST_COMMAND_LOG=str(log),
                   TEST_FAIL_UPDATE="1" if fail_update else "0")
        result = subprocess.run(["bash", str(SCRIPT)], env=env, capture_output=True)
        return result, log.read_text(), unit

    def test_first_boot_installs_current_runtime_and_enables_service(self):
        result, commands, unit = self.run_bootstrap()
        self.assertEqual(result.returncode, 0)
        self.assertIn("t3 update --channel stable --yes", commands)
        self.assertIn("t3 service install", commands)
        self.assertIn("systemctl --user enable --now t3code.service", commands)
        self.assertEqual(unit.read_text(), "managed-runtime")

    def test_rebuild_preserves_installed_runtime_and_restarts_user_service(self):
        result, commands, unit = self.run_bootstrap(installed=True)
        self.assertEqual(result.returncode, 0)
        self.assertNotIn("t3 update", commands)
        self.assertIn("systemctl --user restart t3code.service", commands)
        self.assertEqual(unit.read_text(), "existing-newer-runtime")

    def test_failed_download_does_not_claim_service_is_enabled(self):
        result, commands, unit = self.run_bootstrap(fail_update=True)
        self.assertEqual(result.returncode, 7)
        self.assertNotIn("enable --now", commands)
        self.assertEqual(unit.read_text(), "managed-runtime")


if __name__ == "__main__":
    unittest.main()
