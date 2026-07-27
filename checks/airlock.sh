# Workspace identity capsules — discover per-machine profiles without encoding
# private profile names or paths in the public dotfiles source.

hdr "airlock"

airlock_root="${XDG_CONFIG_HOME:-$HOME/.config}/airlock"
profiles=("$airlock_root"/profiles/*.gitconfig)

if [[ ! -e "${profiles[0]}" ]]; then
  ok "no workspace identity profiles configured"
elif ! command -v airlock >/dev/null 2>&1; then
  fail "profiles exist but airlock is not installed"
else
  for profile_file in "${profiles[@]}"; do
    profile=${profile_file##*/}
    profile=${profile%.gitconfig}
    if airlock -p "$profile" doctor >/dev/null 2>&1; then
      ok "$profile profile healthy"
    else
      fail "$profile profile failed: airlock -p $profile doctor"
    fi
  done
fi
