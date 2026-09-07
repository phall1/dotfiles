#!/usr/bin/env bash
# Compatibility entrypoint: use the same inventory and ownership as bootstrap.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec mise -C "$root" bootstrap "$@"
