#!/usr/bin/env bash
# Seed the shared skill tree.
#
# ~/.agents/skills is enrolled in native live preferences, so .chezmoiignore
# excludes it and `chezmoi apply` never writes there. dot_agents/skills is
# therefore a seed, not a copy -- but nothing was seeding it. A skill tracked
# here but absent from the live tree left every harness adapter dangling, and
# because the adapters are symlinks the failure is silent at the filesystem
# level and only shows up as a skill that never loads.
#
# Seed missing files only. The live tree stays authoritative: an existing file
# is never overwritten, so local edits and history restores always win.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
seeds="$root/dot_agents/skills"
live="$HOME/.agents/skills"

[[ -d "$seeds" ]] || exit 0

seeded=0
while IFS= read -r -d '' source; do
  relative="${source#"$seeds"/}"
  target="$live/$relative"
  [[ -e "$target" ]] && continue
  mkdir -p "$(dirname "$target")"
  cp "$source" "$target"
  seeded=$((seeded + 1))
  echo "Seeded shared skill file: ~/.agents/skills/$relative"
done < <(find "$seeds" -type f -print0)

[[ "$seeded" -eq 0 ]] || echo "Seeded $seeded shared skill file(s) into the live tree."
