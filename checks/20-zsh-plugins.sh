# Verify zsh plugins are cloned and at the SHA pinned in plugins.lock.

hdr "zsh plugins"

LOCK="$DOTFILES/plugins.lock"
PLUGIN_DIR="${ZSH_PLUGIN_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins}"

if [[ ! -f "$LOCK" ]]; then
  warn "zsh/plugins.lock missing — nothing to verify"
  return 0 2>/dev/null || true
fi

while read -r name repo ref; do
  [[ -z "$name" || "$name" =~ ^# ]] && continue

  target="$PLUGIN_DIR/$name"
  if [[ ! -d "$target/.git" ]]; then
    fail "$name not installed — run dot-install-zsh-plugins"
    continue
  fi

  # Compare current HEAD against the lockfile ref. If the ref is a SHA,
  # check exact. If it's a branch/tag, check that the ref exists locally.
  current=$(git -C "$target" rev-parse --short HEAD 2>/dev/null)
  desired_sha=$(git -C "$target" rev-parse "$ref" 2>/dev/null || echo "")

  if [[ -z "$desired_sha" ]]; then
    warn "$name @ $current — lockfile ref '$ref' not resolvable (try fetch)"
  elif [[ "$(git -C "$target" rev-parse HEAD)" == "$desired_sha" ]]; then
    ok "$name @ $current"
  else
    warn "$name @ $current — drift from lockfile ($(git -C "$target" rev-parse --short "$ref"))"
  fi
done < "$LOCK"
