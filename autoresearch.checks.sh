#!/bin/bash
set -euo pipefail

PLUGIN_DIR="opencode/.config/opencode/plugin/autoresearch"

if [ -d "$PLUGIN_DIR" ] && [ -f "$PLUGIN_DIR/package.json" ]; then
  (cd "$PLUGIN_DIR" && npm test --silent)

  if git ls-files --error-unmatch .opencode-autoresearch-state.json >/dev/null 2>&1; then
    echo ".opencode-autoresearch-state.json should not be tracked in git" >&2
    exit 1
  fi
else
  node -e "console.log('plugin not created yet; skipping checks')" >/dev/null
fi
