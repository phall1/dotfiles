#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"

mapfile -t packages < <(find . -maxdepth 1 -mindepth 1 -type d \
  ! -name '.git' \
  ! -name '.github' \
  -exec basename {} \; | sort)

if [ ${#packages[@]} -eq 0 ]; then
  echo "No stow packages found." >&2
  exit 0
fi

if [ "$#" -eq 0 ]; then
  set -- -R
fi

echo "Running stow with args: $*"
echo "Packages: ${packages[*]}"
stow "$@" "${packages[@]}"
