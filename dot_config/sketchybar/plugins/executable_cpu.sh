#!/usr/bin/env bash
# cpu.sh — CPU load %. Color shifts orange→red as load increases.

# top -l 1 -n 0: one sample, no process list. Fastest CPU read on macOS.
CPU_LINE=$(top -l 1 -n 0 | grep "CPU usage")
USER_PCT=$(echo "$CPU_LINE" | awk '{print $3}' | tr -d '%')
SYS_PCT=$(echo "$CPU_LINE" | awk '{print $5}' | tr -d '%')
TOTAL=$(awk "BEGIN { printf \"%.0f\", $USER_PCT + $SYS_PCT }")

if [ "$TOTAL" -ge 80 ]; then
  COLOR=0xfff38ba8  # red
elif [ "$TOTAL" -ge 50 ]; then
  COLOR=0xfff9e2af  # yellow
else
  COLOR=0xfffab387  # peach (default ok)
fi

sketchybar --set "$NAME" icon.color="$COLOR" label="${TOTAL}%"
