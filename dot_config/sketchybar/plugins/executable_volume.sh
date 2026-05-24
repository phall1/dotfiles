#!/usr/bin/env bash
# volume.sh — output volume % + speaker icon. Triggered on volume_change.
# Part of system_bracket (with battery). $INFO is the new volume (0-100).

VOLUME="${INFO:-$(osascript -e 'output volume of (get volume settings)')}"

case "$VOLUME" in
  [6-9][0-9]|100) ICON=""; COLOR=0xffa6e3a1 ;;
  [3-5][0-9])     ICON=""; COLOR=0xffcdd6f4 ;;
  [1-9]|[1-2][0-9]) ICON=""; COLOR=0xff6c7086 ;;
  *)              ICON=""; COLOR=0xff6c7086 ;;
esac

sketchybar --set "$NAME" icon="$ICON" \
                         icon.color="$COLOR" \
                         label="${VOLUME}%"
