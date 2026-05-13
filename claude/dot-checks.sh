# Per-package claude checks. Colocated with the package they check.

hdr "claude"

if [[ -f "$HOME/.claude/settings.json" ]]; then
  if python3 -c "import json,sys; json.load(open('$HOME/.claude/settings.json'))" 2>/dev/null; then
    ok "settings.json parses"
  else
    fail "settings.json does not parse as JSON"
  fi
else
  warn "~/.claude/settings.json missing"
fi

# settings.local.json should not contain hardcoded /Users/phall/ paths post-task#2
# (host-specific paths belong in chezmoi templates).
if [[ -f "$HOME/.claude/settings.local.json" ]] \
   && grep -q "/Users/phall/" "$HOME/.claude/settings.local.json" 2>/dev/null; then
  warn "settings.local.json has hardcoded /Users/phall/ — will be templated by chezmoi (task #7)"
fi

# Discover skill state cache exists — seeded by task #8.
if [[ -d "$HOME/.claude/state" ]]; then
  ok "~/.claude/state present (whats-new cache available)"
fi
