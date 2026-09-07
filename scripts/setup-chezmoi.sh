#!/usr/bin/env bash
# Compatibility entrypoint: preserve existing machine data through one writer.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec mise -C "$root" run configure "$@"
