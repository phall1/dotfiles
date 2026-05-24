#!/usr/bin/env bash
# space.sh — paint the focused space pill. $SELECTED is set by sketchybar.

if [ "$SELECTED" = "true" ]; then
  sketchybar --set "$NAME" background.color=0xff89b4fa \
                          icon.color=0xff1e1e2e
else
  sketchybar --set "$NAME" background.color=0xff313244 \
                          icon.color=0xff6c7086
fi
