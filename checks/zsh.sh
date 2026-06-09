# Per-package zsh checks.

hdr "zsh"

# .zshenv should be lean — every non-interactive shell pays its cost.
ZSHENV_MAX_LINES="${ZSHENV_MAX_LINES:-30}"
if [[ -f "$DOTFILES/dot_zshenv" ]]; then
  lines=$(wc -l < "$DOTFILES/dot_zshenv")
  if [[ "$lines" -gt "$ZSHENV_MAX_LINES" ]]; then
    warn ".zshenv has $lines lines (>$ZSHENV_MAX_LINES) — non-interactive shells pay this every invocation"
  else
    ok ".zshenv lean ($lines lines)"
  fi
else
  warn "dot_zshenv missing in source"
fi

# Completion cache freshness.
if [[ -f "$HOME/.zcompdump" ]]; then
  if age_h=$(file_age_h "$HOME/.zcompdump"); then
    if [[ "$age_h" -lt 168 ]]; then
      ok ".zcompdump fresh (${age_h}h)"
    else
      warn ".zcompdump stale (${age_h}h) — completions may miss new tools"
    fi
  fi
else
  warn ".zcompdump missing — first shell start will be slow"
fi

# .zsh_secrets present (gitignored).
if [[ -f "$HOME/.zsh_secrets" ]]; then
  ok ".zsh_secrets present"
else
  warn ".zsh_secrets missing (gitignored — copy from dot_zsh_secrets.example)"
fi

# P10k state: instant-prompt cache + gitstatusd daemon.
ZSH_PLUGIN_DIR="${ZSH_PLUGIN_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins}"
if [[ -d "$ZSH_PLUGIN_DIR/powerlevel10k" ]]; then
  cache="${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${USER}.zsh"
  if [[ -f "$cache" ]]; then
    ok "p10k instant-prompt cache present"
  else
    warn "p10k instant-prompt cache missing — first shell after install is slow until generated"
  fi
  if pgrep -x gitstatusd >/dev/null 2>&1; then
    ok "gitstatusd daemon alive"
  else
    warn "gitstatusd not running (interactive shell hasn't started yet?)"
  fi
fi

# Startup-output hygiene. The instant-prompt preamble paints the terminal early,
# so ANY stdout after it trips p10k's "console output during zsh initialization"
# warning and makes the prompt jump. The sanctioned place for startup output is
# ~/.zsh_early, sourced BEFORE the preamble. Enforce two things:
#   (a) source-side ordering invariant — the hook exists and precedes the preamble.
#   (b) runtime hygiene — late-sourced machine-local files don't echo at load time.
zshrc_src="$DOTFILES/dot_zshrc"
if [[ -f "$zshrc_src" ]]; then
  early_ln=$(grep -n '\.zsh_early' "$zshrc_src" | head -1 | cut -d: -f1)
  ip_ln=$(grep -n 'p10k-instant-prompt' "$zshrc_src" | head -1 | cut -d: -f1)
  if [[ -z "$early_ln" ]]; then
    fail "~/.zsh_early hook missing from dot_zshrc — no sanctioned place for startup output"
  elif [[ -z "$ip_ln" ]]; then
    warn "can't locate p10k instant-prompt block in dot_zshrc — hook ordering unverifiable"
  elif (( early_ln < ip_ln )); then
    ok "~/.zsh_early hook precedes instant-prompt preamble (line $early_ln < $ip_ln)"
  else
    fail "~/.zsh_early sourced AFTER instant-prompt preamble (line $early_ln > $ip_ln) — startup output will break instant prompt"
  fi
fi

# Late-sourced machine-local files must not write stdout at load time. Heuristic:
# a column-0 echo/print/printf/cat with no redirection is load-time stdout;
# function-body output is indented (won't match) and redirected output (>&2, >file)
# is filtered out. A warn, not a fail — it's advisory, and points at the fix.
for late in "$HOME/.zsh_local" "$HOME/.zsh_secrets"; do
  [[ -f "$late" ]] || continue
  disp="~${late#"$HOME"}"
  if grep -nE '^(echo|print|printf|cat)\b' "$late" 2>/dev/null | grep -qvE '>'; then
    warn "$disp emits stdout at load time — move banners to ~/.zsh_early (sourced before instant prompt)"
  else
    ok "$disp clean (no load-time stdout)"
  fi
done

# zsh-bench available (perf measurement substrate).
if command -v zsh-bench >/dev/null 2>&1; then
  ok "zsh-bench installed"
else
  warn "zsh-bench missing — re-run dot-install-zsh-plugins"
fi

# Compiled bytecode (.zwc) — zsh loads .zwc next to the file it sources,
# so for chezmoi-applied files the bytecode lives at $HOME/.zshrc.zwc, not source.
if [[ -f "$HOME/.zshrc.zwc" ]]; then
  if [[ "$HOME/.zshrc" -nt "$HOME/.zshrc.zwc" ]]; then
    warn ".zshrc is newer than .zwc — chezmoi apply should re-run dot-zcompile"
  else
    ok ".zshrc bytecode fresh"
  fi
else
  warn "~/.zshrc.zwc missing — run dot-zcompile (saves ~5-15ms per startup)"
fi
