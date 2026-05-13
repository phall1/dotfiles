#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Time Tracker
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ⏱
# @raycast.argument1 { "type": "text", "placeholder": "Category - Task", "optional": true }
# @raycast.packageName Productivity

# Documentation:
# @raycast.description Start or stop a local time tracker. Pass a task to start; leave empty to stop.
# @raycast.author Patrick Hall

# ---------------------------------------------------------------------------
# 100% local, offline time tracker. No cloud, no APIs, no accounts.
#
# Usage (via Raycast):
#   "Admin - Answering emails"   → starts tracking that task
#   (empty) or "stop"            → stops the current task
#   "Dev - New feature"          → auto-stops previous, starts new
#
# Log:    ~/Desktop/TimeLog.md   (override: export TIMETRACKER_LOG=...)
# State:  ~/.local/state/timetracker/current
#
# Log format (each line is self-contained, safe to hand-edit):
#
#   ## 2026-03-10 Monday
#
#   - 09:15 → 10:30  (1h 15m)  Admin - Answering emails
#   - 10:45 → 12:00  (1h 15m)  Dev - Building time tracker
# ---------------------------------------------------------------------------

set -euo pipefail

LOG_FILE="${TIMETRACKER_LOG:-$HOME/Desktop/TimeLog.md}"
STATE_DIR="$HOME/.local/state/timetracker"
STATE_FILE="$STATE_DIR/current"

task="${1:-}"

format_duration() {
  local total=$1
  local h=$((total / 3600))
  local m=$(( (total % 3600) / 60 ))
  if [[ $h -gt 0 ]]; then
    printf "%dh %dm" "$h" "$m"
  else
    printf "%dm" "$m"
  fi
}

ensure_date_header() {
  local today
  today=$(date +"%Y-%m-%d %A")

  if [[ ! -f "$LOG_FILE" ]]; then
    printf "# Time Log\n" > "$LOG_FILE"
  fi

  if ! grep -qF "## $today" "$LOG_FILE"; then
    printf "\n## %s\n\n" "$today" >> "$LOG_FILE"
  fi
}

stop_task() {
  if [[ ! -f "$STATE_FILE" ]]; then
    echo "No task is currently running"
    exit 0
  fi

  local start_epoch start_time task_name
  IFS='|' read -r start_epoch start_time task_name < "$STATE_FILE" || true

  if [[ -z "${start_epoch:-}" || -z "${task_name:-}" ]]; then
    rm -f "$STATE_FILE"
    echo "Corrupted state file — cleared"
    exit 1
  fi

  local now_epoch stop_time duration duration_str
  now_epoch=$(date +%s)
  stop_time=$(date +"%H:%M")
  duration=$((now_epoch - start_epoch))
  duration_str=$(format_duration "$duration")

  ensure_date_header
  printf "- %s → %s  (%s)  %s\n" \
    "$start_time" "$stop_time" "$duration_str" "$task_name" >> "$LOG_FILE"

  rm -f "$STATE_FILE"
  echo "Stopped: ${task_name} — ${duration_str}"
}

start_task() {
  if [[ -f "$STATE_FILE" ]]; then
    stop_task
  fi

  mkdir -p "$STATE_DIR"

  local start_epoch start_time
  start_epoch=$(date +%s)
  start_time=$(date +"%H:%M")

  printf "%s|%s|%s" "$start_epoch" "$start_time" "$task" > "$STATE_FILE"
  echo "Started: ${task}"
}

task_lower=$(echo "$task" | tr '[:upper:]' '[:lower:]')

if [[ -z "$task" || "$task_lower" = "stop" ]]; then
  stop_task
else
  start_task
fi
