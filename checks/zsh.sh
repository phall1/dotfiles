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

# Completion cache freshness. Age is NOT the signal — dot_zshrc keys cache
# invalidation on fpath directory mtimes, so a months-old dump is correct as
# long as no completion dir has changed under it. What matters: is the dump
# older than a directory that has since gained completions? If so the next
# shell rebuilds it (self-healing), but flag it so a `compdef x=y` against a
# not-yet-registered command isn't a mystery.
if [[ -f "$HOME/.zcompdump" ]]; then
  comp_stale=""
  for d in /opt/homebrew/share/zsh/site-functions /usr/local/share/zsh/site-functions \
           "${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins/zsh-completions/src"; do
    [[ -d "$d" ]] || continue
    if [[ "$d" -nt "$HOME/.zcompdump" ]]; then
      comp_stale="$d"
      break
    fi
  done
  if [[ -n "$comp_stale" ]]; then
    warn ".zcompdump older than $comp_stale — next shell start rebuilds it"
  else
    ok ".zcompdump current with fpath dirs"
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
  # p10k spawns gitstatusd lazily, on the first prompt render. dot-doctor runs
  # non-interactively, so absence here carries no signal: it means no prompt has
  # rendered in this context, not that anything is wrong. Counting zsh processes
  # does not help either — every tool-spawned subshell is one. Only report the
  # daemon when it is present, and only warn when it cannot possibly start.
  gitstatusd_bin="$(find "${XDG_CACHE_HOME:-$HOME/.cache}/gitstatus" -maxdepth 1 -name 'gitstatusd-*' -perm -u+x 2>/dev/null | head -1)"
  if pgrep -x gitstatusd >/dev/null 2>&1; then
    ok "gitstatusd daemon alive"
  elif [[ -n "$gitstatusd_bin" ]]; then
    ok "gitstatusd binary present (spawns on first interactive prompt)"
  else
    warn "gitstatusd binary missing — p10k falls back to slow git status"
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
# `compdef alias=cmd` is a stderr landmine: if the source completion isn't
# registered (tool not installed on this machine, cold completion cache) zsh
# prints "compdef: unknown command or service: <cmd>" during init, which trips
# the instant-prompt warning. Every such line must be guarded by a conditional.
if [[ -f "$zshrc_src" ]]; then
  unguarded=$(grep -nE '^[[:space:]]*compdef[[:space:]]+[A-Za-z0-9_.-]+=' "$zshrc_src" 2>/dev/null || true)
  if [[ -n "$unguarded" ]]; then
    fail "unguarded 'compdef x=y' in dot_zshrc (line ${unguarded%%:*}) — errors to stderr when y is unregistered; wrap in (( \$+_comps[y] ))"
  else
    ok "no unguarded 'compdef x=y' in dot_zshrc"
  fi
fi

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
