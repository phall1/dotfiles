#!/usr/bin/env bash
# space_windows.sh — render app icons inside each space pill.
# Uses sketchybar-app-font ligatures from icon_map.sh ($icon_result).
# Triggered by yabai's windows_on_spaces signal (defined in yabairc).

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/plugins/icon_map.sh"

# Iterate every space yabai knows about.
yabai -m query --spaces 2>/dev/null | jq -r '.[] | .index' | while read -r space_id; do
  [ -z "$space_id" ] && continue

  # Unique sorted app names on this space.
  apps=$(yabai -m query --windows --space "$space_id" 2>/dev/null | \
         jq -r 'map(.app) | unique | .[]')

  icon_strip=""
  while IFS= read -r app; do
    [ -z "$app" ] && continue
    __icon_map "$app"
    # yabai sometimes lowercases process names (e.g. "ghostty"); fall back to
    # title-cased lookup before giving up to :default:.
    if [ "$icon_result" = ":default:" ]; then
      title_app=$(echo "$app" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
      __icon_map "$title_app"
    fi
    icon_strip+="$icon_result "
  done <<< "$apps"

  if [ -n "$icon_strip" ]; then
    sketchybar --set space."$space_id" label="$icon_strip" \
                                       label.drawing=on
  else
    sketchybar --set space."$space_id" label.drawing=off
  fi
done
