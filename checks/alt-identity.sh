# Alt identity completeness — flag half-finished setup so commits don't go
# out as the wrong user. All three pieces (gitconfig, ssh key, gh auth dir)
# must be present together, or none at all.

hdr "alt-identity"

git_alt="$HOME/.gitconfig-alt"
ssh_alt="$HOME/.ssh/id_ed25519_alt"
gh_alt="$HOME/.config/gh-alt"

have_git=0; [[ -f "$git_alt" ]] && have_git=1
have_ssh=0; [[ -f "$ssh_alt" ]] && have_ssh=1
have_gh=0;  [[ -d "$gh_alt" ]] && have_gh=1

count=$((have_git + have_ssh + have_gh))

if [[ "$count" -eq 0 ]]; then
  ok "not configured on this machine"
elif [[ "$count" -eq 3 ]]; then
  name=$(git config -f "$git_alt" user.name 2>/dev/null || true)
  email=$(git config -f "$git_alt" user.email 2>/dev/null || true)
  if [[ -n "$name" && -n "$email" ]]; then
    ok "configured (~/.gitconfig-alt, ssh key, gh-alt config dir all present)"
  else
    warn "$git_alt missing user.name or user.email"
  fi
else
  warn "half-configured (gitconfig=$have_git ssh=$have_ssh gh=$have_gh) — run ~/dotfiles/scripts/setup-alt-identity.sh"
fi
