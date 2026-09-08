# shellcheck shell=bash
# Native mise history is the owner of enrolled live preferences.
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/mise/conf.d/dotfiles-history.toml" ]] || return 0
hdr "self-saving dotfiles"
if history_status="$(mise bootstrap dotfiles status --json 2>/dev/null)"; then
  if jq -e '.history.unavailable != null' <<< "$history_status" >/dev/null; then
    fail "native history is unavailable — mise bootstrap dotfiles status"
  elif jq -e '.history.checkpoints > 0 and .history.pending_operations == 0' <<< "$history_status" >/dev/null; then
    ok "native history has recoverable checkpoints and no unfinished operations"
  else
    warn "history checkpoint pending — let bootstrap finish, then inspect mise bootstrap dotfiles status"
  fi
  if services_enabled; then
    if jq -e '.history.watcher == "running"' <<< "$history_status" >/dev/null; then
      ok "native history watcher running"
    else
      fail "native history watcher is not running — mise bootstrap services apply"
    fi
  fi
  if jq -e '.history.sync != null' <<< "$history_status" >/dev/null; then
    if jq -e '.history.sync | (.conflicts | length) > 0 or .application_failure != null or .validation_error != null' <<< "$history_status" >/dev/null; then
      fail "history synchronization is paused — mise bootstrap dotfiles status"
    elif jq -e '.history.sync.last_error != null' <<< "$history_status" >/dev/null; then
      warn "history synchronization retry pending — mise bootstrap dotfiles status"
    else
      ok "private history origin has no reported synchronization conflicts or errors"
    fi
  elif services_enabled; then
    warn "history is local-only until a private origin is connected"
  fi
  history_managed="$(chezmoi managed --include files,symlinks)"
  history_overlap=0
  while IFS= read -r target; do
    relative="${target#\~/}"
    if awk -v target="$relative" '$0 == target || index($0, target "/") == 1 {found=1} END {exit !found}' <<< "$history_managed"; then
      fail "double-owned preference: $target"
      history_overlap=1
    fi
  done < <(jq -r '.files[] | select(.mode == "track") | .target' <<< "$history_status")
  [[ "$history_overlap" == 1 ]] || ok "native live preferences and chezmoi targets have no overlap"
else
  fail "native history status unavailable"
fi
