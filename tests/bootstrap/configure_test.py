#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["tomlkit==0.13.3"]
# ///
"""Machine configuration regression tests, using private disposable homes."""
import argparse
import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import tomlkit

source = Path(__file__).resolve().parents[2] / "scripts/bootstrap/configure.py"
spec = importlib.util.spec_from_file_location("configure", source)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ConfigureTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory()
        self.addCleanup(self.scratch.cleanup)
        self.home = Path(self.scratch.name)
        self.path = self.home / ".config/chezmoi/chezmoi.toml"
        self.path.parent.mkdir(parents=True)
        self.env = patch.dict(os.environ, {"HOME": str(self.home), "XDG_CONFIG_HOME": str(self.home / ".config"), "MISE_ENV": "container"})
        self.env.start()
        self.addCleanup(self.env.stop)
        self.identity = patch.object(module, "git_identity", return_value="fixture")
        self.identity.start()
        self.addCleanup(self.identity.stop)

    def test_preserves_machine_data_and_is_private_and_idempotent(self):
        self.path.write_text('[data]\nsecret_reference="keep"\nharnesses=["opencode","pi"]\n[data.git]\nname="Personal Name"\nemail="personal@example.invalid"\n')
        args = argparse.Namespace(harnesses=[], services=None)
        module.configure(args)
        first = self.path.read_bytes()
        module.configure(args)
        self.assertEqual(self.path.read_bytes(), first)
        data = tomlkit.parse(first.decode())["data"]
        self.assertEqual(data["secret_reference"], "keep")
        self.assertEqual(data["git"]["name"], "Personal Name")
        self.assertEqual(data["harnesses"], ["opencode", "pi"])
        self.assertFalse(data["services"])
        self.assertEqual(self.path.stat().st_mode & 0o777, 0o600)

    def test_explicit_selection_replaces_previous_harnesses(self):
        self.path.write_text('[data]\nharnesses=["opencode","pi"]\n')
        module.configure(argparse.Namespace(harnesses=["claude"], services="off"))
        self.assertEqual(tomlkit.parse(self.path.read_text())["data"]["harnesses"], ["opencode", "claude"])

    def test_invalid_existing_document_survives(self):
        self.path.write_text("invalid = [")
        before = self.path.read_bytes()
        with self.assertRaises(tomlkit.exceptions.ParseError):
            module.configure(argparse.Namespace(harnesses=[], services=None))
        self.assertEqual(self.path.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
