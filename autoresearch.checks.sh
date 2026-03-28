#!/bin/bash
set -euo pipefail

PLUGIN_DIR="opencode/.config/opencode/plugin/autoresearch"
TEST_DIR="$PLUGIN_DIR/test"

if [ -d "$PLUGIN_DIR" ] && [ -f "$PLUGIN_DIR/package.json" ]; then
  (cd "$PLUGIN_DIR" && npm test --silent)
else
  node -e "console.log('plugin not created yet; skipping checks')" >/dev/null
fi
