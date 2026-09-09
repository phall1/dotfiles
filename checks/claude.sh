# shellcheck shell=bash
# Claude Code. Settings are reconciled by a modify_ script, not copied: herdr
# writes its own hooks into ~/.claude/settings.json live, so chezmoi merges the
# portable managed keys and leaves everything else alone. A plain source-vs-
# target diff is therefore meaningless here -- assert that the managed keys
# actually took, and nothing about the keys we deliberately do not own.

harness_enabled claude || return 0
hdr "claude"

settings="$HOME/.claude/settings.json"
modify="$DOTFILES/dot_claude/modify_settings.json"

if [[ ! -f "$settings" ]]; then
  warn "~/.claude/settings.json missing — run 'chezmoi apply'"
elif ! jq -e 'type == "object"' "$settings" >/dev/null 2>&1; then
  fail "settings.json does not parse as JSON"
else
  ok "settings.json parses"
  # The managed block is the contract. Re-derive it from the modify_ script so
  # this check cannot drift from what chezmoi actually enforces.
  if [[ -x "$modify" ]] && managed="$(sed -n "/^managed='/,/^}'$/p" "$modify" | sed "s/^managed='//; s/^}'$/}/")" \
     && jq -e 'type == "object"' <<< "$managed" >/dev/null 2>&1; then
    if jq -e --argjson managed "$managed" '. as $live | $managed | [paths(scalars) as $p | ($live | getpath($p)) == ($managed | getpath($p))] | all' "$settings" >/dev/null 2>&1; then
      ok "managed settings keys are applied"
    else
      warn "managed settings keys diverge — run 'chezmoi apply'"
    fi
  else
    fail "dot_claude/modify_settings.json is missing, not executable, or its managed block is unreadable"
  fi
fi

# The modify_ script must merge, never replace: a replacing script would erase
# herdr's live hooks on every apply.
if [[ -x "$modify" ]]; then
  probe='{"hooks":{"Stop":[{"keep":true}]},"theme":"light"}'
  merged="$(printf '%s' "$probe" | "$modify" 2>/dev/null)"
  if jq -e '.hooks.Stop[0].keep == true and .theme == "dark"' <<< "$merged" >/dev/null 2>&1; then
    ok "modify_settings merges: unmanaged keys survive, managed keys win"
  else
    fail "modify_settings does not preserve unmanaged keys — it would erase herdr's hooks"
  fi
fi

# Skills reach Claude as symlink adapters into the shared ~/.agents tree.
for adapter in "$DOTFILES"/dot_claude/skills/*/symlink_SKILL.md; do
  [[ -e "$adapter" ]] || continue
  skill="$(basename "$(dirname "$adapter")")"
  live="$HOME/.claude/skills/$skill/SKILL.md"
  if [[ -e "$live" ]]; then
    ok "claude skill adapter: $skill"
  else
    warn "claude skill adapter missing: $skill — run 'chezmoi apply'"
  fi
done

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
