# Only selected harnesses participate in workstation health. The isolated
# fixture suite validates every optional source, even when it is not applied.
hdr "ox alpha routes"
if "$HOME/.local/bin/ox" status >/dev/null 2>&1; then ok "Ox launcher healthy"
else fail "Ox launcher missing or broken"; fi
if jq -e '.providers.opencode.models["x-preview-f-free"] and .providers.openrouter.models["stealth/ox-alpha"] and .providers["ox-command"].models["stealth/ox-alpha"] and .providers["ox-nous"].models["stealth/ox-alpha"] and .providers["ox-venice"].models["stealth-ox-alpha"]' "$HOME/.config/opencode/opencode.jsonc" >/dev/null 2>&1; then
  ok "OpenCode provider fleet configured"
else
  fail "OpenCode provider fleet invalid"
fi
if services_enabled; then
  if opencode2 debug config >/dev/null 2>&1; then ok "OpenCode accepts the managed V2 config"
  else fail "OpenCode rejected the managed config"; fi
fi
if harness_enabled pi; then
  if jq -e --argjson expected '["ox-opencode","ox-openrouter","ox-command","ox-nous","ox-venice"]' '
    (.providers | keys) as $keys | ($expected - $keys | length) == 0
    and ([.providers[$expected[]].models[0].contextWindow] | all(. == 1048576))
    and ([.providers[$expected[]].models[0].maxTokens] | all(. == 131072))
  ' "$HOME/.pi/agent/models.json" >/dev/null 2>&1; then ok "Pi Ox provider catalog valid"
  else fail "Pi Ox catalog invalid"; fi
fi
if harness_enabled hermes; then
  if yq -e '[.custom_providers[] | select(.name == "ox-command" or .name == "ox-venice")] | length == 2' "$HOME/.hermes/config.yaml" >/dev/null 2>&1; then ok "Hermes Ox custom routes valid"
  else fail "Hermes Ox custom routes missing"; fi
fi
if harness_enabled goose; then
  for provider in opencode openrouter command nous venice; do
    if jq -e '.engine == "openai" and .requires_auth and .models[0].context_limit == 1048576' "$HOME/.config/goose/custom_providers/ox_$provider.json" >/dev/null 2>&1; then ok "Goose Ox $provider valid"
    else fail "Goose Ox $provider missing or invalid"; fi
  done
fi
if harness_enabled grok; then
  if yq -p=toml -o=json -e '.model."ox-opencode" and .model."ox-venice"' "$HOME/.grok/config.toml" >/dev/null 2>&1; then ok "Grok Ox catalog valid"
  else fail "Grok Ox catalog invalid"; fi
fi
for harness in pi claude hermes goose grok; do
  harness_enabled "$harness" || continue
  command -v "$harness" >/dev/null || fail "selected harness $harness is not installed"
done
