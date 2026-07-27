# chezmoi source/target reconciliation checks.
#
# The failure mode this guards against: you (or a tool's installer) edit a file
# in $HOME, the chezmoi source doesn't know, and the next `chezmoi apply`
# silently reverts it. `chezmoi status` reports two columns — the FIRST is
# "target changed since chezmoi last wrote it", which is exactly that case.

hdr "chezmoi"

if ! command -v chezmoi >/dev/null 2>&1; then
  warn "chezmoi not installed — skipping"
  return 0 2>/dev/null || true
else

status_out=$(chezmoi status 2>/dev/null)

# First column non-blank and not '?' => the live file drifted from what chezmoi
# wrote. Those are the ones apply would clobber. Second-column-only entries just
# mean the source moved ahead, which is a normal pending apply.
drifted=$(printf '%s\n' "$status_out" | awk '/^[^ ?]/ {print $NF}')
if [[ -n "$drifted" ]]; then
  n=$(printf '%s\n' "$drifted" | grep -c .)
  warn "$n target(s) modified outside chezmoi — 'chezmoi apply' would revert them:"
  printf '%s\n' "$drifted" | sed 's/^/      /'
  printf "      fix: chezmoi re-add <path>   (NOTE: silently skips .tmpl files)\n"
else
  ok "no targets modified outside chezmoi"
fi

# A modify_ script's stdout REPLACES its target file, so a script that fails
# and prints nothing truncates the config to zero bytes. That is exactly what
# dot_codex/modify_config.toml did once tomlq was installed: its merge fed both
# TOML documents in as one stream, tomlq rejected the duplicate tables, and the
# script emitted nothing. Checking "is tomlq installed" would not have caught
# it -- installing tomlq is what triggered it. So smoke-test the real invariant
# instead: feed the script the live config and require usable output back.
modify_script="$DOTFILES/dot_codex/modify_config.toml"
codex_cfg="$HOME/.codex/config.toml"
if [[ -f "$modify_script" && -f "$codex_cfg" ]]; then
  out=$(sh "$modify_script" < "$codex_cfg" 2>/dev/null)
  if [[ -z "$out" ]]; then
    fail "codex modify_ script produced EMPTY output — 'chezmoi apply' would truncate $codex_cfg"
  elif ! printf '%s\n' "$out" | grep -qE '^model[[:space:]]*='; then
    fail "codex modify_ output is missing the [model] key — merge is mangling the config"
  else
    n=$(printf '%s\n' "$out" | grep -c .)
    ok "codex modify_ script round-trips cleanly ($n lines)"
  fi
fi

fi
