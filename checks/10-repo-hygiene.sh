# Repo-wide hygiene. Things that should NEVER drift back in.

hdr "Repo hygiene"

# No personal username hardcodes in tracked configs.
# Excludes: doctor's own check files (they mention the pattern as a search target),
# raycast author attribution comments, and the .git dir.
_hits=$(grep -rn "Patrick\.Hall" \
    --include="*.zsh" --include="*.sh" --include="*.json" --include="*.jsonc" \
    --include="*.toml" --include=".zshrc" --include=".zshenv" --include=".zprofile" \
    --exclude-dir=".git" --exclude-dir="checks" --exclude="dot-checks.sh" \
    "$DOTFILES" 2>/dev/null | grep -v "raycast.author" || true)
if [[ -n "$_hits" ]]; then
  fail "hardcoded Patrick.Hall paths remain in tracked configs:"
  printf '      %s\n' "$_hits"
else
  ok "no hardcoded Patrick.Hall paths in tracked configs"
fi
unset _hits

# Repo cleanliness — informational, not a fail.
if [[ -n "$(cd "$DOTFILES" && git status --porcelain 2>/dev/null)" ]]; then
  warn "uncommitted changes in dotfiles repo"
else
  ok "dotfiles repo clean"
fi
