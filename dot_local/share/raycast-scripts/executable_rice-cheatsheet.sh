#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Rice Cheatsheet
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🎛
# @raycast.packageName Rice
# @raycast.refreshTime 1d

# Documentation:
# @raycast.description Show the yabai/skhd/sketchybar cheatsheet in a Raycast popup.
# @raycast.author Patrick Hall

# ---------------------------------------------------------------------------
# Renders ~/docs/RICE-CHEATSHEET.md inside Raycast's full-output panel.
# Raycast's fullOutput renders markdown, so tables/headings show up nicely.
# Assign a global hotkey via Raycast > Extensions > Rice Cheatsheet.
# ---------------------------------------------------------------------------

CHEATSHEET="${RICE_CHEATSHEET:-$HOME/docs/RICE-CHEATSHEET.md}"

if [ ! -f "$CHEATSHEET" ]; then
  echo "# Cheatsheet not found"
  echo
  echo "Expected at \`$CHEATSHEET\`."
  echo "Set \`RICE_CHEATSHEET\` to override the path."
  exit 1
fi

cat "$CHEATSHEET"
