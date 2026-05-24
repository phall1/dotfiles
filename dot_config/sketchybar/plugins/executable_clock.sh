#!/usr/bin/env bash
# clock.sh — render the time. Edit DATE_FMT to change format.

DATE_FMT="%a %b %d  %H:%M"
sketchybar --set "$NAME" label="$(date +"$DATE_FMT")"
