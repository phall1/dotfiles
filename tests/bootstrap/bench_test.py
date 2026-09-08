#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""Exercise the real benchmark gate with the platform's /bin/bash."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

BENCH = Path(__file__).resolve().parents[2] / "dot_local/bin/executable_dot-bench"


class BenchTests(unittest.TestCase):
    def setUp(self):
        self.scratch = tempfile.TemporaryDirectory(prefix="dotfiles-bench-")
        self.home = Path(self.scratch.name).resolve()
        tools = self.home / "bin"
        tools.mkdir()
        self.perf = self.home / "PERF.md"
        self.perf.write_text("first_prompt_lag_ms: 1\n")
        stub = tools / "zsh-bench"
        stub.write_text('#!/bin/sh\nprintf "%s\\n" "$BENCH_OUTPUT"\nexit "${BENCH_RC:-0}"\n')
        stub.chmod(0o755)
        self.env = {
            "HOME": str(self.home), "PATH": f"{tools}:/usr/bin:/bin",
            "DOTFILES": str(self.home), "XDG_STATE_HOME": str(self.home / "state"),
        }

    def tearDown(self):
        self.scratch.cleanup()

    def bench(self, output, **overrides):
        return subprocess.run(["/bin/bash", str(BENCH)], cwd=self.home,
                              env={**self.env, "BENCH_OUTPUT": output, **overrides},
                              capture_output=True, text=True, timeout=30)

    def test_real_gate_passes_and_persists_numeric_results(self):
        result = self.bench("exit_time_ms=2\nfirst_prompt_lag_ms=1.05")
        self.assertEqual(result.returncode, 0, result.stderr)
        record = next((self.home / "state/dotfiles/bench").glob("*.json"))
        self.assertEqual(json.loads(record.read_text())["results"], {"exit_time_ms": 2, "first_prompt_lag_ms": 1.05})

    def test_real_gate_rejects_large_regression_on_stock_bash(self):
        result = self.bench("first_prompt_lag_ms=99999")
        self.assertEqual(result.returncode, 2, result.stderr)
        self.assertIn("regressed", result.stdout)

    def test_missing_or_invalid_measurements_cannot_pass(self):
        for output in ("", "first_prompt_lag_ms=broken", "first_prompt_lag_ms=01", "command_lag_ms=0"):
            with self.subTest(output=output):
                self.assertNotEqual(self.bench(output).returncode, 0)
        self.assertNotEqual(self.bench("first_prompt_lag_ms=1", BENCH_RC="7").returncode, 0)

    def test_declared_baselines_must_be_positive_numbers(self):
        for baseline in ("", "broken", "0", "1 2"):
            with self.subTest(baseline=baseline):
                self.perf.write_text(f"first_prompt_lag_ms: {baseline}\n")
                self.assertNotEqual(self.bench("first_prompt_lag_ms=99999").returncode, 0)
        self.perf.write_text("first_prompt_lag_ms:1\n")
        self.assertEqual(self.bench("first_prompt_lag_ms=99999").returncode, 2)

    def test_fallback_cannot_certify_unmeasured_pinned_metrics(self):
        (self.home / "bin/zsh-bench").unlink()
        result = self.bench("", ITERATIONS="1")
        self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main()
