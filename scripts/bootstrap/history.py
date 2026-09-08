#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["tomlkit==0.13.3"]
# ///
"""Seed native mise history and relinquish chezmoi ownership before capture."""
import json
import os
from pathlib import Path

import tomlkit

from configure import write_private_config


def tracking_entries(manifest: dict) -> dict:
    entries = {f"~/{path}": {"mode": "track"} for path in manifest["shared"]}
    for path in manifest["macos"]:
        entries[f"~/{path}"] = {"mode": "track", "variants": [{"os": "macos"}]}
    entries["~/.config/mise/conf.d/dotfiles-history.toml"] = {"mode": "track"}
    return entries


def history_config(manifest: dict) -> dict:
    return {
        "min_version": "2026.9.3",
        "settings": {"history": {"sync": "sync"}},
        "history": {
            "exclude": manifest["exclude"],
            "reload": {"~/.zsh*": "~/.local/bin/dot-zcompile", "~/.p10k.zsh": "~/.local/bin/dot-zcompile"},
        },
        "dotfiles": tracking_entries(manifest),
        "bootstrap": {
            "repos": {"~/dotfiles": {"url": "https://github.com/phall1/dotfiles.git", "ref": "feat/mise-workstation"}},
            "services": {"mise-history": {"builtin": "history-watch", "environment": {"MISE_CACHE_DIR": "~/.cache/mise"}}},
        },
        "tasks": {"bootstrap": {"run": 'mise -C "$HOME/dotfiles" bootstrap --yes'}},
    }


def watcher_directories(home: Path, config_home: Path) -> dict:
    roots = {
        "MISE_CONFIG_DIR": config_home / "mise",
        "MISE_CACHE_DIR": Path(os.environ.get("XDG_CACHE_HOME", home / ".cache")) / "mise",
        "MISE_DATA_DIR": Path(os.environ.get("XDG_DATA_HOME", home / ".local/share")) / "mise",
        "MISE_STATE_DIR": Path(os.environ.get("XDG_STATE_HOME", home / ".local/state")) / "mise",
    }
    return {key: os.environ.get(key, str(path)) for key, path in roots.items()}


def enable_history(root: Path, home: Path) -> None:
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
    destination = config_home / "mise/conf.d/dotfiles-history.toml"
    manifest = json.loads((root / "provision/dotfiles-history.json").read_text())
    # After enrollment this file is live-owned too. Never overwrite user edits
    # or tracking decisions arriving from another machine on a repeated run.
    if not destination.exists():
        write_private_config(destination, history_config(manifest))
    path = config_home / "chezmoi/chezmoi.toml"
    config = tomlkit.parse(path.read_text())
    config["data"]["history"] = True
    write_private_config(path, config)
    # Service selection is machine-local and excluded from shared history.
    state = "running" if config["data"].get("services", True) else "absent"
    service = {"bootstrap": {"services": {"mise-history": {
        "builtin": "history-watch", "state": state,
        "environment": watcher_directories(home, config_home),
    }}}}
    write_private_config(config_home / "mise/conf.d/zz-dotfiles-services.local.toml", service)


if __name__ == "__main__":
    enable_history(Path(__file__).resolve().parents[2], Path.home())
