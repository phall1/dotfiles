# Repo-wide hygiene. Things that should NEVER drift back in.

hdr "Repo hygiene"

# Chezmoi's extensionless and attribute-prefixed files are configurations too.
_hits=$(git -C "$DOTFILES" grep -n -I -E '/(Users|home)/(phall|Patrick[.]Hall)(/|$)' \
    -- 'dot_*' 'Library/**' '*.tmpl' 'scripts/**' 2>/dev/null || true)
if [[ -n "$_hits" ]]; then
  fail "hardcoded user paths remain in tracked configs:"
  printf '      %s\n' "$_hits"
else
  ok "no hardcoded user paths in tracked configs"
fi
unset _hits

# Repo cleanliness — informational, not a fail.
if [[ -n "$(cd "$DOTFILES" && git status --porcelain 2>/dev/null)" ]]; then
  warn "uncommitted changes in dotfiles repo"
else
  ok "dotfiles repo clean"
fi
