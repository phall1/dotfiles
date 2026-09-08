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

fi
