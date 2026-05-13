# Host-specific checks — flag setups that won't work on this platform.

hdr "host"

case "$(uname -s)" in
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      ok "homebrew installed"
    else
      warn "brew missing — run scripts/bootstrap-darwin.sh"
    fi
    ;;
  Linux)
    if command -v apt-get >/dev/null 2>&1; then
      ok "apt available"
    elif command -v nix >/dev/null 2>&1; then
      ok "nix available (no apt — assuming non-debian distro)"
    else
      warn "no apt or nix — run scripts/bootstrap-linux.sh"
    fi
    # Pi-specific: arm64 verify
    if [[ "$(uname -m)" == "aarch64" || "$(uname -m)" == "arm64" ]]; then
      ok "arm64 (likely Pi 4/5)"
    fi
    ;;
  *)
    warn "unsupported OS: $(uname -s)"
    ;;
esac

# Both platforms: shell should be zsh.
case "$SHELL" in
  */zsh) ok "default shell is zsh" ;;
  *)     warn "default shell is $SHELL — run \`chsh -s \$(command -v zsh)\`" ;;
esac
