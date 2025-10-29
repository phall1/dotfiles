#!/usr/bin/env bash
# Migrate stow-shaped repo to chezmoi-shaped flat source tree.
#
# For each top-level stow package (zsh, git, claude, …), move every
# tracked file UP to the repo root, renaming leading `.` to `dot_`
# (chezmoi's convention). Then delete the now-empty package directory.
#
# Idempotent: if a destination already exists, skips with a warning.
# Uses `git mv` to preserve history.
#
# Special-cases:
#   - bin/.local/bin/<scripts>   → dot_local/bin/<scripts>
#   - git/.gitconfig.template    → dot_gitconfig.tmpl  (chezmoi template)
#   - checks/, docs/, scripts/   → KEEP at root (not chezmoi-applied)
#
# Files starting with `.zsh_secrets.example` etc. stay tracked. Anything
# matching `.gitignore`'d patterns is skipped.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Packages to migrate. Order doesn't matter.
PACKAGES=(
  zsh bin claude direnv gh-dash ghostty git gitui goose lazygit
  neovim nix npm opencode pi raycast sesh starship tig tmux
)

# Non-package top-level dirs that stay where they are.
# (chezmoi only applies things named `dot_*` or other special names.)
SKIP_DIRS=(checks docs scripts .git .github .claude)

dot_rename() {
  # Convert a path like ".zshrc" or ".config/ghostty/config" to
  # "dot_zshrc" / "dot_config/ghostty/config".
  local p="$1"
  case "$p" in
    .*) echo "dot_${p#.}" ;;
    *)  echo "$p" ;;
  esac
}

moved=0
skipped=0
collisions=0

for pkg in "${PACKAGES[@]}"; do
  [[ -d "$pkg" ]] || continue

  # Files inside the package, including hidden ones.
  while IFS= read -r -d '' src; do
    # src looks like "zsh/.zshrc" or "zsh/.zsh/aliases.zsh"
    rel="${src#$pkg/}"
    new_top=$(dot_rename "${rel%%/*}")
    if [[ "$rel" == */* ]]; then
      dst="$new_top/${rel#*/}"
    else
      dst="$new_top"
    fi

    # Special-case: .gitconfig.template → dot_gitconfig.tmpl (chezmoi template).
    case "$dst" in
      dot_gitconfig.template) dst="dot_gitconfig.tmpl" ;;
    esac

    # Skip already-migrated.
    if [[ -e "$dst" ]]; then
      printf "  ! collision %s → %s\n" "$src" "$dst" >&2
      collisions=$((collisions + 1))
      continue
    fi

    mkdir -p "$(dirname "$dst")"
    if git mv -k "$src" "$dst" 2>/dev/null; then
      printf "    %-50s → %s\n" "$src" "$dst"
      moved=$((moved + 1))
    else
      printf "  ? skip %s (not tracked or mv failed)\n" "$src" >&2
      skipped=$((skipped + 1))
    fi
  done < <(find "$pkg" -type f -print0)

  # Remove now-empty package dir (and any empty subdirs left behind).
  find "$pkg" -depth -type d -empty -delete 2>/dev/null || true
done

printf "\nmoved=%d  skipped=%d  collisions=%d\n" "$moved" "$skipped" "$collisions"
