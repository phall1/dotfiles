#!/usr/bin/env bash
# front_app.sh — show the focused app name. Triggered by front_app_switched.

if [ "$SENDER" = "front_app_switched" ]; then
  sketchybar --set "$NAME" label="$INFO"
fi
