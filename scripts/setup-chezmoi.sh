#!/usr/bin/env bash
# setup-chezmoi.sh — interactive per-machine chezmoi.toml writer.
# Writes ~/.config/chezmoi/chezmoi.toml with git identity for THIS machine.
# Idempotent: prompts before overwriting an existing config.

set -euo pipefail

CONFIG_DIR="$HOME/.config/chezmoi"
CONFIG_FILE="$CONFIG_DIR/chezmoi.toml"

BLD=$'\033[1m'; DIM=$'\033[2m'; GRN=$'\033[32m'; YLW=$'\033[33m'; RST=$'\033[0m'

echo "${BLD}chezmoi per-machine setup${RST}"
echo "${DIM}writes $CONFIG_FILE${RST}"
echo

if [[ -f "$CONFIG_FILE" ]]; then
  echo "${YLW}Existing config:${RST}"
  sed 's/^/  /' "$CONFIG_FILE"
  echo
  read -p "Overwrite? [y/N] " reply
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    echo "Keeping existing config. Done."
    exit 0
  fi
fi

# Sensible defaults — try to detect from existing global git config.
default_name="$(git config --global user.name 2>/dev/null || true)"
default_email="$(git config --global user.email 2>/dev/null || true)"

read -p "Git name [${default_name}]: " name
name="${name:-$default_name}"
[[ -n "$name" ]] || { echo "Name required."; exit 1; }

read -p "Git email [${default_email}]: " email
email="${email:-$default_email}"
[[ -n "$email" ]] || { echo "Email required."; exit 1; }

read -p "GPG signing key (optional, leave empty to skip): " signingkey

mkdir -p "$CONFIG_DIR"
{
  echo "# Per-machine chezmoi config — NOT in the dotfiles repo."
  echo "# Each machine carries its own identity here."
  echo
  echo "sourceDir = \"~/dotfiles\""
  echo
  echo "[data.git]"
  echo "    name  = \"$name\""
  echo "    email = \"$email\""
  if [[ -n "$signingkey" ]]; then
    echo "    signingkey = \"$signingkey\""
  fi
} > "$CONFIG_FILE"

echo
echo "${GRN}✓${RST} wrote $CONFIG_FILE"
echo
echo "${BLD}next:${RST}  chezmoi apply"
