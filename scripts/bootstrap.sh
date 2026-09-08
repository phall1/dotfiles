#!/usr/bin/env bash
# Seed only. All workstation inventory and orchestration lives in mise.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
if ! command -v mise >/dev/null; then
  curl --proto '=https' --tlsv1.2 -fsSL https://mise.run | MISE_VERSION=2026.9.3 sh
fi
for config in "$root"/mise*.toml; do mise trust "$config"; done
exec mise -C "$root" bootstrap "$@"
