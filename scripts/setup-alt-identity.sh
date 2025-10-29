#!/usr/bin/env bash
# setup-alt-identity.sh — interactive one-time bootstrap for the alt GitHub
# identity on this machine.
#
# Writes:
#   ~/.gitconfig-alt              identity read by `git identity alt`
#   ~/.ssh/id_ed25519_alt[.pub]   key bound to Host github.com-alt
# Initializes:
#   ~/.config/gh-alt/             gh auth state for the alt account
#
# Re-runnable: prompts before overwriting any existing file.

set -euo pipefail

GIT_ALT="$HOME/.gitconfig-alt"
SSH_KEY="$HOME/.ssh/id_ed25519_alt"
GH_DIR="$HOME/.config/gh-alt"

BLD=$'\033[1m'; DIM=$'\033[2m'; GRN=$'\033[32m'; YLW=$'\033[33m'; RST=$'\033[0m'

prompt_val() {
  local q="$1" def="${2:-}" reply
  if [[ -n "$def" ]]; then
    read -p "$q [$def]: " reply
    echo "${reply:-$def}"
  else
    read -p "$q: " reply
    echo "$reply"
  fi
}

confirm() {
  local reply
  read -p "$1 [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

echo "${BLD}alt identity setup${RST}"
echo "${DIM}writes $GIT_ALT, $SSH_KEY, and initializes $GH_DIR${RST}"
echo

# --- ~/.gitconfig-alt ------------------------------------------------------
if [[ -f "$GIT_ALT" ]]; then
  echo "${YLW}existing $GIT_ALT:${RST}"
  sed 's/^/  /' "$GIT_ALT"
  echo
  if confirm "rewrite?"; then
    rm "$GIT_ALT"
  else
    echo "keeping existing $GIT_ALT"
  fi
fi

if [[ ! -f "$GIT_ALT" ]]; then
  name=$(prompt_val "alt git name")
  [[ -n "$name" ]] || { echo "name required"; exit 1; }
  email=$(prompt_val "alt git email")
  [[ -n "$email" ]] || { echo "email required"; exit 1; }
  signingkey=$(prompt_val "alt signing key (optional, empty to skip)" "")

  {
    echo "# Per-machine alt identity — read by ~/.local/bin/git-identity."
    echo "[user]"
    echo "    name = $name"
    echo "    email = $email"
    if [[ -n "$signingkey" ]]; then
      echo "    signingkey = $signingkey"
      echo "[commit]"
      echo "    gpgsign = true"
    fi
  } > "$GIT_ALT"
  chmod 600 "$GIT_ALT"
  echo "${GRN}✓${RST} wrote $GIT_ALT"
fi

# --- ~/.ssh/id_ed25519_alt -------------------------------------------------
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ -f "$SSH_KEY" ]]; then
  echo "${GRN}✓${RST} ssh key already exists: $SSH_KEY"
else
  key_email=$(git config -f "$GIT_ALT" user.email)
  echo "generating ssh key for $key_email..."
  ssh-keygen -t ed25519 -f "$SSH_KEY" -C "$key_email" -N ""
  echo "${GRN}✓${RST} generated $SSH_KEY"
fi

echo
echo "${BLD}upload this public key to the alt GitHub account:${RST}"
echo "  https://github.com/settings/ssh/new  ${DIM}(while signed in as the alt user)${RST}"
echo
sed 's/^/  /' "$SSH_KEY.pub"
echo

# --- gh auth login ---------------------------------------------------------
mkdir -p "$GH_DIR"
if GH_CONFIG_DIR="$GH_DIR" gh auth status >/dev/null 2>&1; then
  echo "${GRN}✓${RST} gh already authenticated in $GH_DIR"
else
  echo "${BLD}gh auth login${RST} (alt account, separate config dir)"
  echo "${DIM}you'll be prompted to authenticate in a browser — sign in as the alt user${RST}"
  echo
  if confirm "run gh auth login now?"; then
    GH_CONFIG_DIR="$GH_DIR" gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key
  else
    echo "skipped. run later with:"
    echo "  GH_CONFIG_DIR=$GH_DIR gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key"
  fi
fi

echo
echo "${GRN}✓${RST} alt identity setup complete"
echo
echo "${BLD}usage:${RST}"
echo "  in a freshly cloned alt repo:  ${DIM}git identity alt${RST}"
echo "  alt-flavored gh:               ${DIM}gh-alt repo list${RST}"
echo "  show a repo's identity:        ${DIM}git identity${RST}"
