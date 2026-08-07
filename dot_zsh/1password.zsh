# Lazily unlock the 1Password CLI session: only on first actual `op` use in
# a shell, not on every shell open. `op signin` blocks on a password prompt,
# so an eager version (run unconditionally at shell startup) prompts even in
# shells that never touch 1Password — that's needlessly disruptive.
if command -v op &>/dev/null; then
  op() {
    command op whoami &>/dev/null || eval "$(command op signin)"
    command op "$@"
  }
fi
