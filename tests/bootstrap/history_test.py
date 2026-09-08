#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["tomlkit==0.13.3"]
# ///
"""Exercise released mise history with isolated homes and a local Git origin."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "scripts/bootstrap"))
from history import history_config, watcher_directories


class Machine:
    def __init__(self, home: Path, mise: str):
        self.home = home
        self.mise = mise
        home.mkdir()
        self.env = {
            "HOME": str(home), "PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin",
            "XDG_CONFIG_HOME": str(home / ".config"), "XDG_DATA_HOME": str(home / ".local/share"),
            "XDG_CACHE_HOME": str(home / ".cache"), "XDG_STATE_HOME": str(home / ".local/state"),
            "MISE_SYSTEM_CONFIG_DIR": str(home / "system"), "MISE_YES": "1",
            "GIT_CONFIG_NOSYSTEM": "1", "GIT_TERMINAL_PROMPT": "0", "TERM": "dumb",
        }
        self.command("git", "config", "--global", "user.name", "History Fixture")
        self.command("git", "config", "--global", "user.email", "fixture@example.invalid")

    def command(self, *args, check=True):
        return subprocess.run(args, cwd=self.home, env=self.env, text=True,
                              capture_output=True, check=check, timeout=90)

    def run(self, *args, check=True):
        return self.command(self.mise, "bootstrap", "dotfiles", *args, check=check)

    def seed(self):
        config = self.home / ".config/mise/config.toml"
        config.parent.mkdir(parents=True)
        config.write_text('''[settings.history]
sync = "manual"
notify = false
watch.debounce = "100ms"
watch.reconcile = "1s"
[dotfiles]
"~/.config/mise/config.toml" = { mode = "track" }
"~/.fixture" = { mode = "track" }
[tasks.bootstrap]
run = "test -f \\"$HOME/.fixture\\""
''')
        (self.home / ".fixture").write_text("baseline\n")
        self.command(self.mise, "trust", str(config))
        self.run("save")


class HistoryTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(prefix="mise-history-")
        self.root = Path(self.scratch.name).resolve()
        self.a = Machine(self.root / "a", MISE)
        self.a.seed()

    def tearDown(self):
        self.scratch.cleanup()

    def test_watcher_uses_same_directories_as_shell(self):
        from unittest.mock import patch
        with patch.dict(os.environ, self.a.env, clear=True):
            directories = watcher_directories(self.a.home, self.a.home / ".config")
        self.assertEqual(directories["MISE_CACHE_DIR"], str(self.a.home / ".cache/mise"))
        self.assertEqual(directories["MISE_STATE_DIR"], str(self.a.home / ".local/state/mise"))
        with patch.dict(os.environ, {**self.a.env, "MISE_CACHE_DIR": "/custom/cache"}, clear=True):
            self.assertEqual(watcher_directories(self.a.home, self.a.home / ".config")["MISE_CACHE_DIR"], "/custom/cache")
        manifest = {"shared": [], "macos": [], "exclude": []}
        self.assertEqual(history_config(manifest)["bootstrap"]["services"]["mise-history"]["environment"]["MISE_CACHE_DIR"], "~/.cache/mise")

    def test_restore_autosave_and_atomic_edit(self):
        target = self.a.home / ".fixture"
        target.write_text("edited\n")
        self.a.run("save")
        self.a.run("rollback", str(target), "--yes")
        self.assertEqual(target.read_text(), "baseline\n")
        self.a.run("undo", "--yes")
        self.assertEqual(target.read_text(), "edited\n")
        with tempfile.TemporaryFile(mode="w+") as log:
            watcher = subprocess.Popen([MISE, "bootstrap", "dotfiles", "watch", "--json"],
                                       cwd=self.a.home, env=self.a.env, stdout=log, stderr=log)
            try:
                self.wait_for_started(log, watcher)
                replacement = target.with_suffix(".new")
                replacement.write_text("atomic-save\n")
                replacement.replace(target)
                self.wait_for_saved(self.a, target, watcher)
            except AssertionError as error:
                log.seek(0)
                self.fail(f"{error}\nWatcher log:\n{log.read()}")
            finally:
                watcher.terminate()
                watcher.wait(timeout=15)

    def test_deleted_shell_sources_do_not_execute_stale_bytecode(self):
        compiler = Path(__file__).resolve().parents[2] / "dot_local/bin/executable_dot-zcompile"
        module = self.a.home / ".zsh/fixture.zsh"
        module.parent.mkdir()
        sources = [self.a.home / ".zshrc", self.a.home / ".zshenv", self.a.home / ".p10k.zsh", module]
        for source in sources:
            source.write_text('print -r -- stale-bytecode-fixture\n')
        self.a.command("zsh", "-f", str(compiler))
        for source in sources:
            self.assertTrue(Path(str(source) + ".zwc").is_file())
            source.unlink()
        self.a.command("zsh", "-f", str(compiler))
        for source in sources:
            self.assertFalse(Path(str(source) + ".zwc").exists())
        result = self.a.command("zsh", "-i", "-c", "exit")
        self.assertNotIn("stale-bytecode-fixture", result.stdout)

    def wait_for_started(self, log, watcher):
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            self.assertIsNone(watcher.poll(), "native watcher exited unexpectedly")
            log.seek(0)
            if '"event":"started"' in log.read():
                return
            time.sleep(0.2)
        self.fail("native watcher did not start within 30 seconds")

    def wait_for_saved(self, machine, target, watcher):
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            self.assertIsNone(watcher.poll(), "native watcher exited unexpectedly")
            result = machine.run("history", "diff", "--path", str(target), "--exit-code", check=False)
            if result.returncode == 0:
                return
            time.sleep(0.2)
        self.fail(f"native watcher did not save the atomic replacement: {result.stdout} {result.stderr}")

    def test_two_machine_adoption_sync_conflict_and_delete(self):
        origin = self.root / "origin.git"
        self.a.command("git", "init", "--bare", str(origin))
        self.a.run("origin", "set", str(origin), "--sync", "manual", "--yes")
        self.a.run("sync")
        b = Machine(self.root / "b", MISE)
        b.command(MISE, "bootstrap", "--adopt", str(origin), "--yes")
        target_a = self.a.home / ".fixture"
        target_b = b.home / ".fixture"
        self.assertEqual(target_b.read_text(), "baseline\n")
        target_b.write_text("from-b\n")
        b.run("save")
        b.run("sync")
        self.a.run("sync")
        self.a.run("pull", "--yes")
        self.assertEqual(target_a.read_text(), "from-b\n")
        target_a.write_text("a-conflict\n")
        target_b.write_text("b-conflict\n")
        self.a.run("save")
        b.run("save")
        self.a.run("sync")
        b.run("sync", check=False)
        b.run("pull", "--yes", check=False)
        self.assertEqual(target_b.read_text(), "b-conflict\n")
        b.run("pull", "--take-remote", str(target_b), "--yes")
        self.assertEqual(target_b.read_text(), "a-conflict\n")
        target_b.unlink()
        b.run("save")
        b.run("sync")
        self.a.run("sync")
        self.a.run("pull", "--yes")
        self.assertFalse(target_a.exists())


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mise", default=shutil.which("mise"), required=False)
    args, remaining = parser.parse_known_args()
    MISE = str(Path(args.mise).resolve())
    unittest.main(argv=[__file__, *remaining])
