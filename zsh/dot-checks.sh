# Per-package zsh checks. Colocated with the package they check.

hdr "zsh"

# .zshenv should be lean — every non-interactive shell pays its cost.
# Threshold is intentionally low; if you legitimately need more, raise it
# in a commit and explain why.
ZSHENV_MAX_LINES="${ZSHENV_MAX_LINES:-30}"
if [[ -f "$DOTFILES/zsh/.zshenv" ]]; then
  lines=$(wc -l < "$DOTFILES/zsh/.zshenv")
  if [[ "$lines" -gt "$ZSHENV_MAX_LINES" ]]; then
    warn ".zshenv has $lines lines (>$ZSHENV_MAX_LINES) — non-interactive shells pay this every invocation"
  else
    ok ".zshenv lean ($lines lines)"
  fi
else
  warn ".zshenv missing — XDG vars / EDITOR / minimal PATH belong here, not .zshrc"
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
  warn ".zsh_secrets missing (gitignored — copy from zsh/.zsh_secrets.example)"
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

# Compiled bytecode (.zwc) — startup wins compound across rebuilds.
zwc_path="$DOTFILES/zsh/.zshrc.zwc"
if [[ -f "$zwc_path" ]]; then
  if [[ "$DOTFILES/zsh/.zshrc" -nt "$zwc_path" ]]; then
    warn ".zshrc is newer than .zwc — re-run dot-zcompile"
  else
    ok ".zshrc bytecode fresh"
  fi
else
  warn ".zshrc.zwc missing — run dot-zcompile (saves ~5-15ms per startup)"
fi
