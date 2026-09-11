# shellcheck shell=bash
# Scheduled disk reclamation — macOS launchd agent and the tools it drives.
hdr "scheduled disk cleanup"

if [[ "$(uname -s)" != "Darwin" ]]; then
  ok "dot-cleanup is macOS-only — nothing scheduled here"
  return 0
fi

want_bin mo "dot-cleanup needs mole — brew install mole"
want_bin cargo-clean-all "dot-cleanup cargo sweep needs it — cargo install cargo-clean-all"

if [[ -x "$HOME/.local/bin/dot-cleanup" ]]; then
  ok "dot-cleanup installed"
else
  warn "dot-cleanup not applied — chezmoi apply"
fi

plist="$HOME/Library/LaunchAgents/com.phall1.dot-cleanup.plist"
if [[ ! -f "$plist" ]]; then
  ok "launchd agent not managed on this host (services-off profile)"
  return 0
fi
if launchctl list 2>/dev/null | grep -q "com.phall1.dot-cleanup"; then
  ok "dot-cleanup launchd agent loaded (daily 3am)"
else
  warn "dot-cleanup agent not loaded — chezmoi apply"
fi

age_h="$(file_age_h "$HOME/.local/state/dot-cleanup/cleanup.log" 2>/dev/null || echo 999999)"
if [[ "$age_h" -lt 49 ]]; then
  ok "dot-cleanup ran ${age_h}h ago"
else
  warn "dot-cleanup has no run logged in the last 48h"
fi
