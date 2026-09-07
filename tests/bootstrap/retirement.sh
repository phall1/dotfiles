#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-retirement.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$scratch/tests"
cp "$root/tests/gha-local-smoke.sh" "$scratch/tests/gha-local-smoke.sh"
HOME="$scratch" bash "$root/scripts/bootstrap/retire-legacy.sh"
[[ ! -e "$scratch/tests/gha-local-smoke.sh" ]]
printf '%s\n' 'local user work' > "$scratch/tests/gha-local-smoke.sh"
if HOME="$scratch" bash "$root/scripts/bootstrap/retire-legacy.sh" 2>/dev/null; then exit 1; fi
grep -qx 'local user work' "$scratch/tests/gha-local-smoke.sh"
echo 'PASS: only exact retired copies are deleted; local edits survive'
