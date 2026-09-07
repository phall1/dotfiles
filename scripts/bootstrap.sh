#!/usr/bin/env bash
# Seed only. All workstation inventory and orchestration lives in mise.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$HOME/.local/bin:$PATH"
if ! command -v mise >/dev/null; then
  curl --proto '=https' --tlsv1.2 -fsSL https://mise.run | MISE_VERSION=2026.9.1 sh
fi
for config in "$root"/mise*.toml; do mise trust "$config"; done
exec mise -C "$root" bootstrap "$@"
