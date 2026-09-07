#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec uv run --script "$root/scripts/bootstrap/configure.py" "$@"
