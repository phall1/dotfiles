#!/usr/bin/env bash
# front_app.sh — show focused app's glyph + name.
# Fires on front_app_switched AND on initial render (no SENDER).
# icon_map.sh provides __icon_map() which sets $icon_result to a :name: ligature
# that sketchybar-app-font renders as the app's glyph.

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/plugins/icon_map.sh"

if [ -z "$INFO" ]; then
  INFO=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null)
fi

if [ -z "$INFO" ]; then exit 0; fi

__icon_map "$INFO"
sketchybar --set "$NAME" icon="$icon_result" label="$INFO"
