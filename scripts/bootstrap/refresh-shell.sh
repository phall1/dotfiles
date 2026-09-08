#!/usr/bin/env bash
# Resolve stable shims outside startup so upgrades invalidate cached init code.
set -euo pipefail
cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/evalcache"
mkdir -p "$cache"
for tool in zoxide fzf; do
  resolved="$(mise which "$tool")"
  stamp="$cache/$tool.tool"
  if [[ ! -f "$stamp" ]] || [[ "$(cat "$stamp")" != "$resolved" ]]; then
    rm -f "$cache/$tool.zsh"
    printf '%s\n' "$resolved" > "$stamp"
  fi
done
