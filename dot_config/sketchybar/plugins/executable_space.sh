#!/usr/bin/env bash
# space.sh — paint the focused space pill. $SELECTED is set by sketchybar.

if [ "$SELECTED" = "true" ]; then
  sketchybar --set "$NAME" background.color=0xff45d0bd \
                          icon.color=0xff071012
else
  sketchybar --set "$NAME" background.color=0xff111b1f \
                          icon.color=0xff60706e
fi
