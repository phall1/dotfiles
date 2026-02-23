#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

stow_dir="$script_dir"
target_dir="$HOME"

# DOTFILES_SKIP_PACKAGES: comma or space-separated list of packages to skip
# Example: DOTFILES_SKIP_PACKAGES="ghostty,sesh" ./stow-all.sh
skip_packages="${DOTFILES_SKIP_PACKAGES:-}"

mapfile -t packages < <(find "$stow_dir" -maxdepth 1 -mindepth 1 -type d \
  ! -name '.git' \
  ! -name '.github' \
  ! -name 'scripts' \
  ! -name 'docs' \
  -exec basename {} \; | sort)

# Filter out skipped packages
if [ -n "$skip_packages" ]; then
  # Normalize separators: replace commas with spaces
  skip_packages="${skip_packages//,/ }"
  filtered=()
  for pkg in "${packages[@]}"; do
    skip=false
    for s in $skip_packages; do
      if [ "$pkg" == "$s" ]; then
        skip=true
        echo "Skipping package: $pkg"
        break
      fi
    done
    $skip || filtered+=("$pkg")
  done
  packages=("${filtered[@]}")
fi

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
