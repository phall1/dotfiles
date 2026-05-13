# claude checks. chezmoi-aware: files are real copies, not symlinks.

hdr "claude"

if [[ -f "$HOME/.claude/settings.json" ]]; then
  if python3 -c "import json,sys; json.load(open('$HOME/.claude/settings.json'))" 2>/dev/null; then
    ok "settings.json parses"
  else
    fail "settings.json does not parse as JSON"
  fi

  # Drift detection: does the applied copy match the chezmoi source?
  src="$DOTFILES/dot_claude/settings.json"
  if [[ -f "$src" ]] && ! diff -q "$src" "$HOME/.claude/settings.json" >/dev/null 2>&1; then
    warn "settings.json diverges from source — run 'chezmoi apply' (or 'chezmoi diff' to inspect)"
  else
    ok "settings.json matches source"
  fi
else
  warn "~/.claude/settings.json missing — run 'chezmoi apply'"
fi

# Custom agents — tracked count vs applied count.
if [[ -d "$DOTFILES/dot_claude/agents" ]]; then
  tracked=$(find "$DOTFILES/dot_claude/agents" -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
  applied=$(find "$HOME/.claude/agents" -maxdepth 1 -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$tracked" -eq "$applied" ]]; then
    ok "custom agents tracked ($tracked file(s))"
  else
    warn "agent count mismatch — tracked=$tracked applied=$applied. Move untracked agents into \$DOTFILES/dot_claude/agents/ and 'chezmoi apply'"
  fi
fi

# settings.local.json (project-local Claude permissions). Gitignored via global.
if [[ -f "$DOTFILES/.claude/settings.local.json" ]] \
   && grep -q "/Users/phall/" "$DOTFILES/.claude/settings.local.json" 2>/dev/null; then
  # Project-local file with hardcoded path is fine — it's host-specific anyway.
  :
fi
