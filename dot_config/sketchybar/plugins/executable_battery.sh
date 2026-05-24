#!/usr/bin/env bash
# battery.sh — show battery percent + icon. Triggered on power_source_change.

PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

if [ -z "$PERCENTAGE" ]; then exit 0; fi

case "${PERCENTAGE}" in
  9[0-9]|100) ICON=""; COLOR=0xffa6e3a1 ;;
  [6-8][0-9]) ICON=""; COLOR=0xffa6e3a1 ;;
  [3-5][0-9]) ICON=""; COLOR=0xfff9e2af ;;
  [1-2][0-9]) ICON=""; COLOR=0xfffab387 ;;
  *)          ICON=""; COLOR=0xfff38ba8 ;;
esac

if [ -n "$CHARGING" ]; then
  ICON=""
  COLOR=0xff89b4fa
fi

sketchybar --set "$NAME" icon="$ICON" \
                         icon.color="$COLOR" \
                         label="${PERCENTAGE}%"
