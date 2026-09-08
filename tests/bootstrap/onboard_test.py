#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Check onboarding boundaries without installing tools or using credentials."""
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / "scripts/onboard.sh"


class OnboardingTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(prefix="dotfiles-onboard-")
        self.root = Path(self.scratch.name).resolve()
        self.home = self.root / "home"
        self.bin = self.home / ".local/bin"
        self.bin.mkdir(parents=True)
        self.calls = self.root / "calls"
        self.caller = self.root / "unrelated-project"
        self.caller.mkdir()
        self.env = {
            "HOME": str(self.home), "PATH": f"{self.bin}:/usr/bin:/bin",
            "CALLS": str(self.calls), "PLATFORM": "Darwin",
        }
        self.tool("uname", 'echo "$PLATFORM"')
        self.tool("brew", 'echo "brew $*" >> "$CALLS"')
        self.tool("git", 'test "${IDENTITY_MISSING:-0}" = 0 && echo fixture')
        self.tool("gh", '''echo "gh $*" >> "$CALLS"
if [ "$2" = status ]; then exit "${AUTH_RC:-0}"; fi''')
        self.tool("mise", '''echo "mise $*" >> "$CALLS"
echo "cwd=$PWD cache=$XDG_CACHE_HOME state=$XDG_STATE_HOME" >> "$CALLS"
if [ "$2" = --help ]; then echo "${ADOPT_HELP:---adopt}"; exit 0; fi
if [ "$2" = --adopt ]; then exit "${ADOPT_RC:-0}"; fi
if [ "$3" = sync ]; then exit "${SYNC_RC:-0}"; fi''')
        self.tool("dot-doctor", 'echo doctor >> "$CALLS"; exit "${DOCTOR_RC:-0}"')
        self.tool("dot-bench", 'echo bench >> "$CALLS"; exit "${BENCH_RC:-0}"')

    def tearDown(self):
        self.scratch.cleanup()

    def tool(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/sh\n" + body + "\n")
        path.chmod(0o755)

    def onboard(self, **overrides):
        return subprocess.run(["/bin/bash", str(SCRIPT)], cwd=self.caller,
                              env={**self.env, **overrides}, capture_output=True,
                              text=True, timeout=30)

    def test_adoption_uses_home_and_shared_lock_roots(self):
        result = self.onboard()
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.calls.read_text()
        self.assertIn(f"cwd={self.home} cache={self.home}/.cache state={self.home}/.local/state", calls)
        self.assertIn("mise bootstrap --adopt phall1/dotfiles-history --yes", calls)
        self.assertLess(calls.index("--adopt phall1"), calls.index("dotfiles save"))
        self.assertLess(calls.index("dotfiles sync"), calls.index("doctor"))
        self.assertIn("Onboarding complete", result.stdout)
        self.assertNotIn("brew install", calls)

    def test_existing_directory_overrides_are_preserved(self):
        result = self.onboard(XDG_CACHE_HOME=str(self.root / "cache"), XDG_STATE_HOME=str(self.root / "state"))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"cache={self.root}/cache state={self.root}/state", self.calls.read_text())

    def test_final_checks_see_newly_installed_tools(self):
        data = self.root / "custom-mise-data"
        shims = data / "shims"
        shims.mkdir(parents=True)
        tool = shims / "atuin"
        tool.write_text("#!/bin/sh\nexit 0\n")
        tool.chmod(0o755)
        self.tool("dot-doctor", 'command -v atuin >/dev/null || exit 2')
        result = self.onboard(MISE_DATA_DIR=str(data))
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_bad_prerequisites_stop_before_adoption(self):
        for overrides in ({"AUTH_RC": "1"}, {"IDENTITY_MISSING": "1"}, {"ADOPT_HELP": "old mise"}):
            with self.subTest(overrides=overrides):
                self.calls.unlink(missing_ok=True)
                result = self.onboard(**overrides)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("--adopt phall1", self.calls.read_text())

    def test_download_command_never_executes_a_partial_response(self):
        readme = SCRIPT.parents[1] / "README.md"
        command = next(line for line in readme.read_text().splitlines() if line.startswith("onboard=$(curl"))
        self.tool("curl", "printf '%s\\n' 'echo partial-script-executed'\nexit 22")
        for shell in ("/bin/bash", "/bin/zsh"):
            with self.subTest(shell=shell):
                result = subprocess.run([shell, "-f", "-c", command], cwd=self.caller,
                                        env=self.env, capture_output=True, text=True, timeout=30)
                self.assertEqual(result.returncode, 22, result.stderr)
                self.assertNotIn("partial-script-executed", result.stdout)

    def test_download_command_runs_the_complete_entrypoint(self):
        readme = SCRIPT.parents[1] / "README.md"
        command = next(line for line in readme.read_text().splitlines() if line.startswith("onboard=$(curl"))
        self.tool("curl", 'cat "$ONBOARD_SOURCE"')
        result = subprocess.run(["/bin/zsh", "-f", "-c", command], cwd=self.caller,
                                env={**self.env, "ONBOARD_SOURCE": str(SCRIPT)},
                                capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Onboarding complete", result.stdout)

    def test_adoption_or_sync_failure_never_reports_completion(self):
        for key in ("ADOPT_RC", "SYNC_RC"):
            with self.subTest(key=key):
                self.calls.unlink(missing_ok=True)
                result = self.onboard(**{key: "7"})
                self.assertEqual(result.returncode, 7)
                self.assertNotIn("Onboarding complete", result.stdout)
                self.assertNotIn("doctor", self.calls.read_text())

    def test_validation_runs_both_checks_and_keeps_failures_visible(self):
        for overrides in ({"DOCTOR_RC": "2"}, {"BENCH_RC": "2"}):
            with self.subTest(overrides=overrides):
                self.calls.unlink(missing_ok=True)
                result = self.onboard(**overrides)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("doctor\nbench\n", self.calls.read_text())
                self.assertNotIn("Onboarding complete", result.stdout)
        result = self.onboard(DOCTOR_RC="1")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("complete with the doctor warnings", result.stdout)


if __name__ == "__main__":
    unittest.main()
