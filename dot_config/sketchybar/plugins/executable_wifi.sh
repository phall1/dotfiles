#!/usr/bin/env bash
# wifi.sh — current WiFi SSID.
# Uses `ipconfig getsummary en0` because `networksetup -getairportnetwork`
# requires Location permission on macOS 14+ and returns "not associated"
# without it (even when actually connected).

SSID=$(ipconfig getsummary en0 2>/dev/null | awk -F' SSID : ' '/ SSID : / {print $2; exit}')

if [ -z "$SSID" ]; then
  sketchybar --set "$NAME" icon="" icon.color=0xff60706e label="off"
else
  # Truncate long SSIDs for the bar.
  if [ "${#SSID}" -gt 16 ]; then
    SSID="${SSID:0:14}…"
  fi
  sketchybar --set "$NAME" icon="" icon.color=0xff45d0bd label="$SSID"
fi
