#!/usr/bin/env bash
# Install the portable command-line agent stack. Runtime credentials/state stay local.
set -euo pipefail

PI_VERSION=0.84.1
WEB_VERSION=2.1.11
BLACKBIRD_VERSION=0.1.6
NPM_PREFIX="${NPM_CONFIG_PREFIX:-$HOME/.npm-global}"

if ! command -v npm >/dev/null 2>&1; then
  echo "ERROR: npm is required. Install an LTS Node with fnm, then rerun." >&2
  exit 1
fi

mkdir -p "$NPM_PREFIX" "$HOME/.local/bin"
npm install --global --ignore-scripts --prefix "$NPM_PREFIX" \
  "@earendil-works/pi-coding-agent@$PI_VERSION" \
  "open-websearch@$WEB_VERSION"

pi_bin="$NPM_PREFIX/bin/pi"
for package in \
  npm:pi-subagents@0.47.1 \
  npm:@juicesharp/rpiv-ask-user-question@2.4.0 \
  npm:@narumitw/pi-goal@0.51.0 \
  npm:@ff-labs/pi-fff@0.10.3 \
  npm:pi-mcp-adapter@2.23.0 \
  npm:pi-web-access@0.22.0
do
  "$pi_bin" install "$package"
done

install_blackbird_linux_release() (
  local arch target base archive tmp
  arch="$(uname -m)"
  case "$arch" in
    aarch64|arm64) target=aarch64-unknown-linux-gnu ;;
    x86_64|amd64) target=x86_64-unknown-linux-gnu ;;
    *) echo "ERROR: unsupported Linux architecture for Blackbird: $arch" >&2; return 1 ;;
  esac
  base="https://github.com/phall1/blackbird/releases/download/v${BLACKBIRD_VERSION}"
  archive="blackbird-v${BLACKBIRD_VERSION}-${target}.tar.gz"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL "$base/$archive" -o "$tmp/$archive"
  curl -fsSL "$base/$archive.sha256" -o "$tmp/$archive.sha256"
  (cd "$tmp" && sha256sum -c "$archive.sha256")
  tar -xzf "$tmp/$archive" -C "$tmp"
  install -m 0755 "$(find "$tmp" -type f -name blackbird -print -quit)" "$HOME/.local/bin/blackbird"
  install -m 0755 "$(find "$tmp" -type f -name blackbird-claude -print -quit)" "$HOME/.local/bin/blackbird-claude"
)

case "$(uname -s)" in
  Darwin)
    command -v brew >/dev/null 2>&1 || { echo "ERROR: Homebrew is required for Blackbird on Darwin" >&2; exit 1; }
    brew tap phall1/tap
    if brew list --formula blackbird >/dev/null 2>&1; then brew upgrade blackbird; else brew install blackbird; fi
    ;;
  Linux)
    if command -v brew >/dev/null 2>&1; then
      brew tap phall1/tap
      if brew list --formula blackbird >/dev/null 2>&1; then brew upgrade blackbird; else brew install blackbird; fi
    else
      install_blackbird_linux_release
    fi
    ;;
  *) echo "ERROR: unsupported operating system: $(uname -s)" >&2; exit 1 ;;
esac

# Idempotently install/start the service and supported client registrations.
blackbird install

if [[ "$(uname -s)" == Linux ]] && ! command -v brew >/dev/null 2>&1; then
  # Release installs cannot use the Homebrew-dependent updater. Unit names are
  # intentionally tolerant across systemd user-service revisions.
  systemctl --user disable --now blackbird-update.timer blackbird-update.service 2>/dev/null || true
  rm -f "$HOME/.config/systemd/user/blackbird-update.timer" \
        "$HOME/.config/systemd/user/blackbird-update.service"
  systemctl --user daemon-reload 2>/dev/null || true
fi

actual_blackbird="$(blackbird --version 2>/dev/null || printf unknown)"
echo "Agent stack installed: Pi $PI_VERSION, Open WebSearch $WEB_VERSION, Blackbird $actual_blackbird"
