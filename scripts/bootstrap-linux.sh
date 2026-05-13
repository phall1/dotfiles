#!/usr/bin/env bash
# bootstrap-linux.sh — install host-level dependencies on Linux (Pi, Debian, Ubuntu).
# Idempotent. Re-run any time. Falls back to nix when apt packages aren't available.

set -euo pipefail

# apt is mandatory — this is for debian/ubuntu/raspberry pi os
if ! command -v apt-get >/dev/null 2>&1; then
  echo "ERROR: bootstrap-linux.sh expects apt. For other distros, install equivalents manually."
  exit 1
fi

sudo apt-get update

# Packages available in default Debian/Ubuntu/Raspbian repos.
apt_packages=(
  zsh git curl
  fd-find bat ripgrep jq
  age
  tmux neovim
  build-essential pkg-config libssl-dev
)
echo "Installing apt packages..."
sudo apt-get install -y "${apt_packages[@]}"

# fd-find on debian installs as `fdfind` — symlink to `fd` for consistency.
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi
# Same dance for batcat → bat.
if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

# Tools that don't ship via apt or ship outdated — use Nix or upstream installers.
if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Determinate Nix..."
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
  source /etc/profile.d/nix.sh 2>/dev/null \
    || source "$HOME/.nix-profile/etc/profile.d/nix.sh" \
    || true
fi

# Via Nix — version controlled, reproducible.
nix_packages=(
  chezmoi atuin fzf eza delta zoxide
  uv fnm gh
  sesh tig gitui lazygit
)
for pkg in "${nix_packages[@]}"; do
  command -v "$pkg" >/dev/null 2>&1 \
    || nix profile install "nixpkgs#${pkg}" \
    || echo "  (nix install failed for $pkg — install manually if needed)"
done

# Rust (Pi binaries: prefer rustup direct over apt's old rustc).
if ! command -v rustup >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
fi

# Set zsh as default shell.
if [[ "$SHELL" != *zsh ]]; then
  echo "Setting zsh as default shell — you may be prompted for password."
  chsh -s "$(command -v zsh)"
fi

echo "Bootstrap complete. Run: chezmoi apply"
