#!/usr/bin/env bash
# space.sh — paint the focused space indicator. Receives $SELECTED via sketchybar.

if [ "$SELECTED" = "true" ]; then
  sketchybar --set "$NAME" background.color=0xff89b4fa \
                          icon.color=0xff1e1e2e
else
  sketchybar --set "$NAME" background.color=0x00000000 \
                          icon.color=0xff45475a
fi
