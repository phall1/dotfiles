# Critique CLI wrapper — authenticates via GitHub token and routes to our self-hosted worker.
# Prevents accidental upload to public critique.work by requiring CRITIQUE_WORKER_URL.
critique() {
  if ! command -v gh &>/dev/null; then
    echo "Error: gh CLI not found. Install: brew install gh" >&2
    return 1
  fi

  local token
  token=$(gh auth token 2>/dev/null)
  if [[ -z "$token" ]]; then
    echo "Error: gh CLI not authenticated. Run: gh auth login" >&2
    return 1
  fi

  mkdir -p ~/.critique
  printf '{"key":"%s"}\n' "$token" > ~/.critique/license.json
  CRITIQUE_WORKER_URL="${CRITIQUE_WORKER_URL:?Set CRITIQUE_WORKER_URL in your environment}" command critique "$@"
}
