#!/usr/bin/env bash
set -euo pipefail
[[ "$(uname -s)" == Darwin ]] || { echo 'This entrypoint requires macOS.' >&2; exit 1; }
if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
exec bash "$(dirname "${BASH_SOURCE[0]}")/bootstrap.sh" "$@"
