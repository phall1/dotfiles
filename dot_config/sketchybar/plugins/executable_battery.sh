#!/usr/bin/env bash
# battery.sh — battery % + state icon. Triggered on power_source_change.
# Part of system_bracket (with volume).

PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

if [ -z "$PERCENTAGE" ]; then exit 0; fi

case "${PERCENTAGE}" in
  9[0-9]|100) ICON=""; COLOR=0xff7fae8b ;;
  [6-8][0-9]) ICON=""; COLOR=0xff7fae8b ;;
  [3-5][0-9]) ICON=""; COLOR=0xffd6a84f ;;
  [1-2][0-9]) ICON=""; COLOR=0xffc27a4a ;;
  *)          ICON=""; COLOR=0xffe45f57 ;;
esac

if [ -n "$CHARGING" ]; then
  ICON=""
  COLOR=0xff45d0bd
fi

sketchybar --set "$NAME" icon="$ICON" \
                         icon.color="$COLOR" \
                         label="${PERCENTAGE}%"
