#!/usr/bin/env bash
# Standalone entrypoint: it can be downloaded before the checkout exists.
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
# Do not inherit an unrelated project's mise configuration or trust prompts.
cd "$HOME"

require_command() {
  command -v "$1" >/dev/null 2>&1 && return 0
  printf 'Missing prerequisite: %s. Install it, then rerun onboarding.\n' "$1" >&2
  exit 1
}

check_git_identity() {
  local key
  for key in name email; do
    if [[ -z "$(git config --global --get "user.$key" || true)" ]]; then
      printf 'Git identity is missing: run git config --global user.%s <value>, then rerun onboarding.\n' "$key" >&2
      exit 1
    fi
  done
}

check_prerequisites() {
  local tool
  for tool in git gh mise; do require_command "$tool"; done
  if [[ "$(uname -s)" == Darwin ]]; then require_command brew; fi
  if ! mise bootstrap --help | grep -q -- '--adopt'; then
    echo 'Mise 2026.9.3 or newer is required. Update mise, then rerun onboarding.' >&2
    exit 1
  fi
  check_git_identity
  if ! gh auth status --hostname github.com >/dev/null 2>&1; then
    echo 'GitHub login needs attention: run gh auth login --hostname github.com, then rerun onboarding.' >&2
    exit 1
  fi
}

verify_setup() {
  local doctor_rc=0 bench_rc=0
  "$HOME/.local/bin/dot-doctor" || doctor_rc=$?
  "$HOME/.local/bin/dot-bench" || bench_rc=$?
  if (( doctor_rc > 1 || bench_rc != 0 )); then
    echo 'Setup is installed, but validation needs attention. Resolve the checks above and rerun this command.' >&2
    return 1
  fi
  if (( doctor_rc == 1 )); then
    echo 'Onboarding complete with the doctor warnings shown above.'
  else
    echo 'Onboarding complete. Health and performance checks passed.'
  fi
  echo 'Open a new terminal. Enrolled preferences now autosave and synchronize between your machines.'
}

echo '[1/3] Checking your existing tools and GitHub login'
check_prerequisites

echo '[2/3] Restoring shared preferences and provisioning this machine'
mise bootstrap --adopt phall1/dotfiles-history --yes
# This is outside bootstrap's history transaction; explicit saves cannot nest.
mise bootstrap dotfiles save
mise bootstrap dotfiles sync
mise bootstrap dotfiles status

echo '[3/3] Checking the installed setup'
export PATH="$HOME/.local/bin:${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims:$HOME/.cargo/bin:$PATH"
verify_setup
