#!/usr/bin/env bash
# Secret-free Ox Alpha provider catalog across installed coding harnesses.

hdr "ox alpha routes"

ox_bin="$HOME/.local/bin/ox"
pi_models="$HOME/.pi/agent/models.json"
opencode_config="$HOME/.config/opencode/opencode.jsonc"
hermes_config="$HOME/.hermes/config.yaml"
goose_providers="$HOME/.config/goose/custom_providers"
grok_config="$HOME/.grok/config.toml"
codex_config="$HOME/.codex/config.toml"
pi_models_modify="$DOTFILES/dot_pi/private_agent/modify_private_models.json"
hermes_modify="$DOTFILES/dot_hermes/modify_private_config.yaml"

if [[ -x "$ox_bin" ]] && "$ox_bin" status >/dev/null 2>&1; then
  ok "ox launcher and credential inventory"
else
  fail "ox launcher missing or broken"
fi

expected_pi='["ox-opencode","ox-openrouter","ox-command","ox-nous","ox-venice"]'
if [[ -f "$pi_models" ]] && jq -e --argjson expected "$expected_pi" '
  (.providers | keys) as $keys
  | ($expected - $keys | length) == 0
  and ([.providers[$expected[]].models[0].contextWindow] | all(. == 1048576))
  and ([.providers[$expected[]].models[0].maxTokens] | all(. == 131072))
' "$pi_models" >/dev/null 2>&1; then
  ok "Pi Ox provider catalog"
else
  fail "Pi Ox provider catalog missing or inconsistent"
fi

if [[ "$(printf '%s' 'not-json' | "$pi_models_modify")" == not-json ]] && [[ "$(printf '%s' 'not: [valid' | "$hermes_modify")" == 'not: [valid' ]]; then
  ok "Pi and Hermes provider merges fail closed"
else
  fail "Pi or Hermes provider merge erases malformed runtime state"
fi

if [[ -f "$opencode_config" ]] && jq -e '
  .provider.opencode.models["x-preview-f-free"]
  and .provider.openrouter.models["stealth/ox-alpha"]
  and .provider["ox-command"].models["stealth/ox-alpha"]
  and .provider["ox-nous"].models["stealth/ox-alpha"]
  and .provider["ox-venice"].models["stealth-ox-alpha"]
' "$opencode_config" >/dev/null 2>&1; then
  if ! command -v opencode >/dev/null 2>&1; then
    warn "OpenCode Ox catalog present; runtime validation unavailable on this host"
  elif opencode debug config >/dev/null 2>&1; then
    ok "OpenCode config parses with five Ox routes"
  else
    fail "OpenCode rejected its managed config"
  fi
else
  fail "OpenCode Ox routes missing or invalid"
fi

if [[ -f "$hermes_config" ]] && yq -e '
  [.custom_providers[] | select(.name == "ox-command" or .name == "ox-venice")] | length == 2
' "$hermes_config" >/dev/null 2>&1; then
  ok "Hermes native plus custom Ox routes"
else
  fail "Hermes Ox custom routes missing"
fi

missing_goose=''
for provider in opencode openrouter command nous venice; do
  file="$goose_providers/ox_${provider}.json"
  if [[ ! -f "$file" ]] || ! jq -e '.engine=="openai" and .requires_auth==true and .models[0].context_limit==1048576' "$file" >/dev/null 2>&1; then
    missing_goose+=" $provider"
  fi
done
if [[ -z "$missing_goose" ]]; then
  ok "Goose declarative Ox providers"
else
  fail "Goose Ox providers missing or invalid:${missing_goose}"
fi

if [[ ! -f "$grok_config" ]] || ! yq -p=toml -e '.model."ox-opencode" and .model."ox-venice"' "$grok_config" >/dev/null 2>&1; then
  fail "Grok Ox model catalog missing or invalid"
elif ! command -v grok >/dev/null 2>&1; then
  warn "Grok Ox catalog present; runtime validation unavailable on this host"
elif grok models 2>/dev/null | grep -q 'ox-opencode' && grok models 2>/dev/null | grep -q 'ox-venice'; then
  ok "Grok custom Ox model catalog"
else
  fail "Grok rejected its Ox model catalog"
fi

if [[ -f "$codex_config" ]] && grep -q '^\[model_providers\.ox-openrouter\]$' "$codex_config" && grep -q '^\[model_providers\.ox-venice\]$' "$codex_config" && [[ -f "$HOME/.codex/ox-openrouter.config.toml" && -f "$HOME/.codex/ox-venice.config.toml" ]]; then
  ok "Codex Responses profiles for OpenRouter and Venice"
else
  fail "Codex Ox Responses profiles missing"
fi

for binary in pi opencode hermes goose grok codex; do
  command -v "$binary" >/dev/null 2>&1 || warn "$binary missing — Ox route configured but unavailable on this host"
done
