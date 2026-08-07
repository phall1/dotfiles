# Auto-unlock the 1Password CLI session in interactive shells.
# Guarded to interactive-only: `op signin` blocks on a password prompt, and
# running it in non-interactive contexts (scripts, tool probes, git hooks
# spawning zsh) would hang or corrupt their stdout. Skipped silently if `op`
# isn't installed or a session is already live in this shell.
if [[ -o interactive ]] && command -v op &>/dev/null && ! op whoami &>/dev/null; then
  eval "$(op signin)"
fi
