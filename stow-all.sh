#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

stow_dir="$script_dir"
target_dir="$HOME"

mapfile -t packages < <(find "$stow_dir" -maxdepth 1 -mindepth 1 -type d \
  ! -name '.git' \
  ! -name '.github' \
  ! -name 'scripts' \
  -exec basename {} \; | sort)

if [ ${#packages[@]} -eq 0 ]; then
  echo "No stow packages found." >&2
  exit 0
fi

if [ "$#" -eq 0 ]; then
  set -- -R
fi

echo "Stow dir: $stow_dir"
echo "Target dir: $target_dir"
echo "Args: $*"
echo "Packages: ${packages[*]}"
echo ""

# Suppress known stow+nix symlink conflict warnings
stow \
  --dir="$stow_dir" \
  --target="$target_dir" \
  --no-folding \
  "$@" \
  "${packages[@]}" 2>&1 | grep -v "BUG in find_stowed_path" || true
