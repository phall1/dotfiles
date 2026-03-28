#!/bin/bash
set -euo pipefail

PLUGIN_DIR="opencode/.config/opencode/plugin/autoresearch"

# In this dotfiles repo the plugin is meant to be consumed from ~/.config/opencode/plugin,
# so restow the opencode package before running checks.
stow --dir="$PWD" --target="$HOME" --no-folding -R opencode >/dev/null

if [ -d "$PLUGIN_DIR" ] && [ -f "$PLUGIN_DIR/package.json" ]; then
  (cd "$PLUGIN_DIR" && npm test --silent)

  runtime_out="$(mktemp)"
  runtime_err="$(mktemp)"
  trap 'rm -f "$runtime_out" "$runtime_err"' EXIT

  opencode run --format json --command autoresearch off --print-logs --log-level INFO --dir "$PWD" >"$runtime_out" 2>"$runtime_err"

  if rg -q 'failed to load plugin|Command not found' "$runtime_err"; then
    echo "OpenCode runtime smoke test failed:" >&2
    cat "$runtime_err" >&2
    exit 1
  fi
else
  node -e "console.log('plugin not created yet; skipping checks')" >/dev/null
fi
