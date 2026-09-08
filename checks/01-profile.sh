# Shared predicates for optional checks. Profiles are rendered from chezmoi
# data; their absence keeps older installations on the OpenCode core.
harness_enabled() {
  local profile="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/profile.json"
  [[ -f "$profile" ]] || { [[ "$1" == opencode ]]; return; }
  jq -e --arg name "$1" '.harnesses | index($name)' "$profile" >/dev/null
}

services_enabled() {
  local profile="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/profile.json"
  [[ -f "$profile" ]] || return 0
  jq -e '.services == true' "$profile" >/dev/null
}
