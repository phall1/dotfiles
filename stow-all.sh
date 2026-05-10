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

# Pre-flight: detect files that would shadow a stowed dotfile.
# Some tools check multiple paths and prefer one over the other (e.g. tmux 3.1+
# loads ~/.config/tmux/tmux.conf in preference to ~/.tmux.conf), so a stale
# real file in the higher-priority location silently wins over our symlink.
# Format: "<shadow path>|<stowed target it overrides>"
shadow_pairs=(
  "$HOME/.config/tmux/tmux.conf|$HOME/.tmux.conf"
)

shadows_found=()
for pair in "${shadow_pairs[@]}"; do
  shadow="${pair%%|*}"
  target="${pair##*|}"
  # Only flag if the shadow exists as a real file (not a symlink we manage)
  # and the stowed target also exists.
  if [ -e "$shadow" ] && [ ! -L "$shadow" ] && [ -e "$target" ]; then
    shadows_found+=("$shadow shadows $target")
  fi
done

if [ ${#shadows_found[@]} -gt 0 ]; then
  echo "⚠️  Shadow config(s) detected — these will override your stowed dotfiles:"
  for s in "${shadows_found[@]}"; do echo "    $s"; done
  echo ""
  read -r -p "Move them aside (.bak) and continue? [y/N] " reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    for pair in "${shadow_pairs[@]}"; do
      shadow="${pair%%|*}"
      if [ -e "$shadow" ] && [ ! -L "$shadow" ]; then
        mv -v "$shadow" "$shadow.bak"
      fi
    done
  else
    echo "Aborting. Resolve shadows manually and re-run." >&2
    exit 1
  fi
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
