#!/usr/bin/env bash
# Initial installation and health diagnosis are separate native operations.
set -euo pipefail
profile="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/profile.json"
jq -e '.services' "$profile" >/dev/null || exit 0

blackbird_is_absent() {
  local socket_rc=0 process_rc=0
  # curl 7 is connection refusal, unlike a timeout or an answering error page.
  # The process probe also catches a legacy daemon on a different local port.
  curl --silent --output /dev/null --connect-timeout 2 --max-time 2 http://127.0.0.1:8080/health || socket_rc=$?
  pgrep -x blackbird >/dev/null || process_rc=$?
  [[ "$socket_rc" == 7 && "$process_rc" == 1 ]]
}

reconcile_blackbird() {
  local service report rc=0
  service="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/blackbird.service"
  if [[ "$(uname -s)" == Darwin ]]; then service="$HOME/Library/LaunchAgents/com.phall1.blackbird.plist"; fi
  report="$(blackbird doctor --json)" || rc=$?
  printf '%s' "$report" | jq -e '.checks | type == "array"' >/dev/null
  if [[ -e "$service" ]]; then
    (( rc == 0 )) && return 0
    echo 'Existing Blackbird installation needs attention: run blackbird doctor. Its daemon was not restarted.' >&2
    return 1
  fi
  if printf '%s' "$report" | jq -e 'any(.checks[]; .name == "database.schema" and .status == "fail")' >/dev/null; then
    echo 'Blackbird has an incompatible database. Review blackbird doctor before native registration.' >&2
    return 1
  fi
  blackbird_is_absent || {
    echo 'Blackbird absence could not be established. Review blackbird doctor before native registration; existing processes were retained.' >&2
    return 1
  }
  blackbird install
}

disable_linux_brew_updater() {
  [[ "$(uname -s)" == Linux ]] || return 0
  systemctl --user cat blackbird-update.timer >/dev/null 2>&1 || return 0
  systemctl --user disable --now blackbird-update.timer
}

reconcile_phux() {
  local service="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/phux.service"
  if [[ "$(uname -s)" == Darwin ]]; then service="$HOME/Library/LaunchAgents/com.phux.server.plist"; fi
  phux service status >/dev/null 2>&1 && return 0
  if [[ -e "$service" ]]; then
    echo 'Existing Phux service needs attention: run phux service status. Its unit and live panes were retained.' >&2
    return 1
  fi
  phux service install --adopt
}

reconcile_blackbird
disable_linux_brew_updater
# --adopt registers supervision without killing an incumbent's panes.
reconcile_phux
