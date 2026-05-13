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

# gitstatusd daemon alive (P10k runs it; only check if P10k installed).
if [[ -d "$DOTFILES/zsh/.zsh/plugins/powerlevel10k" ]]; then
  if pgrep -x gitstatusd >/dev/null 2>&1; then
    ok "gitstatusd daemon alive"
  else
    warn "P10k installed but gitstatusd not running — restart shell"
  fi
fi
