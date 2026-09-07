#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
for tool in mise node bun uv chezmoi jq yq zsh git opencode2 blackbird phux phux-mcp phig phui lstags; do
  command -v "$tool" >/dev/null || { echo "Missing required executable: $tool" >&2; exit 1; }
done
opencode2 --version
phui --version
phux config check
phig config check
# Config parsing does not exercise Phig's Git minimum. Test an actual repository
# operation even when this source is an archive rather than a Git checkout.
repository="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-git-check.XXXXXX")"
trap 'rm -rf "$repository"' EXIT
git init --quiet "$repository"
phig --repo "$repository" snapshot status >/dev/null
profile="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/profile.json"
while IFS= read -r tool; do
  command -v "$tool" >/dev/null || { echo "Selected harness missing: $tool" >&2; exit 1; }
done < <(jq -r '.harnesses[] | select(. != "opencode")' "$profile")
chezmoi verify --exclude scripts --source "$root"
rc=0
DOTFILES="$root" bash "$root/dot_local/bin/executable_dot-doctor" || rc=$?
(( rc < 2 ))
