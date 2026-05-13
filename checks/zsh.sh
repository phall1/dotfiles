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
