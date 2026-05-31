#!/usr/bin/env bash
# yabai_layout.sh — show current space's layout (bsp/stack/float).
# Fires on: yabai_layout_change (custom), space_change, mouse.clicked, initial render.
# Custom trigger passes layout=<value> which sketchybar exposes as $LAYOUT.

layout="${LAYOUT:-}"
if [ -z "$layout" ]; then
  layout=$(yabai -m query --spaces --space 2>/dev/null | jq -r '.type' 2>/dev/null)
fi

case "$layout" in
  float)
    sketchybar --set "$NAME" icon="" \
                             icon.color=0xfff38ba8 \
                             label="float" \
                             label.color=0xfff38ba8
    ;;
  stack)
    sketchybar --set "$NAME" icon="" \
                             icon.color=0xfff9e2af \
                             label="stack" \
                             label.color=0xfff9e2af
    ;;
  *)
    sketchybar --set "$NAME" icon="" \
                             icon.color=0xffa6e3a1 \
                             label="bsp" \
                             label.color=0xffa6e3a1
    ;;
esac
