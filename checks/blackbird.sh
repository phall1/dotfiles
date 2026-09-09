# Blackbird durable coordination.
#
# Two levels of evidence, because they are not always both available. Where the
# service lifecycle is enabled, ask the runtime what it actually resolved --
# OpenCode accepts MCP servers at both .mcp.<name> and .mcp.servers.<name>, and
# a check that hardcodes one spelling reports a healthy daemon as broken. Where
# it is not (a container, a profile that opts out), no daemon is running to ask,
# so assert the configuration declares the integration correctly instead.
hdr "blackbird"
if ! command -v blackbird >/dev/null; then
  fail "Blackbird missing — run mise bootstrap"
  return 0
fi

bb_configs=()
for config in "$HOME/.config/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.json"; do
  [[ -f "$config" ]] && bb_configs+=("$config")
done

# Accept either MCP placement, in any of the loaded documents.
bb_declared=1
for config in "${bb_configs[@]}"; do
  jq -e '((.mcp.blackbird // .mcp.servers.blackbird) | .url) == "http://127.0.0.1:8081"' "$config" >/dev/null 2>&1 && bb_declared=0
done

bb_plugin_declared=1
for config in "${bb_configs[@]}"; do
  jq -e 'any((.plugins // [])[]; type == "object" and (.package // "" | startswith("blackbird-opencode")))' "$config" >/dev/null 2>&1 && bb_plugin_declared=0
done

if ! command -v opencode2 >/dev/null 2>&1; then
  warn "OpenCode absent — Blackbird delivery integration unverified"
elif services_enabled; then
  # A daemon is running, so resolved state is the stronger claim.
  if ! mcp_list="$(opencode2 mcp list 2>/dev/null)"; then
    fail "OpenCode could not enumerate MCP servers"
  elif grep -qE '^\s*✓\s+blackbird\b' <<< "$mcp_list"; then
    ok "Blackbird MCP endpoint connected"
  elif grep -qE '^\s*[⚠○]\s+blackbird\b' <<< "$mcp_list"; then
    fail "Blackbird MCP server is registered but not connected — blackbird doctor"
  else
    fail "Blackbird MCP server is not registered with OpenCode"
  fi
  if opencode2 plugin list 2>/dev/null | grep -qE '^\S*blackbird\s'; then
    ok "Blackbird push-delivery plugin loaded"
  else
    fail "Blackbird OpenCode plugin is not loaded — opencode2 plugin list"
  fi
else
  (( bb_declared )) && fail "Blackbird MCP endpoint is not declared in OpenCode config" \
                    || ok "Blackbird MCP endpoint declared"
  (( bb_plugin_declared )) && fail "Blackbird push-delivery plugin is not declared in OpenCode config" \
                           || ok "Blackbird push-delivery plugin declared"
fi

# A credential belongs in the store, never in a tracked or synced config.
bb_credential_leak=0
for config in "${bb_configs[@]}"; do
  if ! jq -e '[(.plugins // [])[] | select(type == "object" and (.package // "" | startswith("blackbird-opencode"))) | .options // {}] | all(has("token") | not)' "$config" >/dev/null 2>&1; then
    fail "Blackbird plugin options carry a literal token in ${config/#$HOME/\~} — use the credential store"
    bb_credential_leak=1
  fi
done
(( bb_credential_leak )) || ok "no literal Blackbird credentials in OpenCode config"

if services_enabled; then
  if blackbird doctor >/dev/null 2>&1; then ok "native doctor healthy"
  else fail "Blackbird service needs attention — blackbird doctor"; fi
else
  ok "service lifecycle disabled by this machine profile"
fi
