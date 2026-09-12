# Grok and Cursor both ship `agent`. Unique names must stay unique.

hdr "agent CLIs"

want_bin grok "Grok CLI"
want_bin cursor-agent "Cursor CLI"

agent_bin="$HOME/.local/bin/agent"
if [[ -L "$agent_bin" ]]; then
  target=$(readlink "$agent_bin")
  if [[ "$target" == *cursor-agent* ]]; then
    warn "~/.local/bin/agent is a Cursor installer symlink — chezmoi apply (use grok / cursor-agent)"
  else
    warn "~/.local/bin/agent is a symlink -> $target"
  fi
elif [[ -x "$agent_bin" ]] && grep -q 'ambiguous on this machine' "$agent_bin" 2>/dev/null; then
  ok "~/.local/bin/agent is the disambiguator"
elif [[ -e "$agent_bin" ]]; then
  warn "~/.local/bin/agent exists but is not the disambiguator"
else
  fail "~/.local/bin/agent missing — chezmoi apply"
fi

# grok's installer appends a PATH prepend; that's fine if we re-assert
# ~/.local/bin after it so the disambiguator still wins.
if grep -q '>>> grok installer >>>' "$HOME/.zshrc" 2>/dev/null; then
  if grep -A20 '>>> grok installer >>>' "$HOME/.zshrc" | grep -q 'path=("$HOME/.local/bin"'; then
    ok "~/.zshrc re-asserts ~/.local/bin after grok installer"
  else
    warn "~/.zshrc grok installer PATH prepend is last — re-assert ~/.local/bin after it"
  fi
else
  ok "~/.zshrc has no grok installer PATH append"
fi
