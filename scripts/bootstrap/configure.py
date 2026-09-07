#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["tomlkit==0.13.3"]
# ///
"""Persist machine-local selections without replacing identity or secret data."""
import argparse
import os
from pathlib import Path
import subprocess
import tempfile

import tomlkit

HARNESSES = ("opencode", "pi", "claude", "hermes", "goose", "grok")


def harness_name(value: str) -> str:
    if value not in HARNESSES:
        raise argparse.ArgumentTypeError(f"unknown harness {value!r}; choose from {', '.join(HARNESSES)}")
    return value


def git_identity(key: str) -> str:
    result = subprocess.run(["git", "config", "--global", "--get", key], capture_output=True, text=True)
    return result.stdout.strip()


def write_private_config(path: Path, config: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)  # tempfile creates it private before writing
        try:
            stream.write(tomlkit.dumps(config))
            stream.flush()
            os.fsync(stream.fileno())
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)


def configure(args: argparse.Namespace) -> None:
    home = Path.home()
    source = Path(__file__).resolve().parents[2]
    path = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config")) / "chezmoi/chezmoi.toml"
    config = tomlkit.parse(path.read_text()) if path.exists() else tomlkit.document()
    config["sourceDir"] = str(source)
    data = config.setdefault("data", tomlkit.table())
    identity = data.setdefault("git", tomlkit.table())
    identity.setdefault("name", git_identity("user.name"))
    identity.setdefault("email", git_identity("user.email"))
    if not identity["name"] or not identity["email"]:
        raise SystemExit("Set git config --global user.name and user.email before bootstrap.")
    selected = args.harnesses or data.get("harnesses", ["opencode"])
    environments = os.environ.get("MISE_ENV", "").split(",")
    selected = [*selected, *(name for name in environments if name in HARNESSES)]
    data["harnesses"] = list(dict.fromkeys(["opencode", *selected]))
    if args.services is not None:
        data["services"] = args.services == "on"
    data.setdefault("services", "container" not in os.environ.get("MISE_ENV", "").split(","))
    write_private_config(path, config)
    print("Configured harnesses:", ", ".join(data["harnesses"]))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("harnesses", nargs="*", type=harness_name)
    parser.add_argument("--services", choices=("on", "off"))
    configure(parser.parse_args())
