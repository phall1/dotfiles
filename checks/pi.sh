# Pi agent-stack checks. Runtime-owned state is inspected, never reconciled here.

hdr "pi agent stack"

pi_settings="$HOME/.pi/agent/settings.json"
pi_modify="$DOTFILES/dot_pi/agent/modify_settings.json"
subagent_config="$HOME/.pi/agent/extensions/subagent/config.json"
module_bridge="$HOME/.pi/agent/node_modules"
mcp_config="$HOME/.config/mcp/mcp.json"

if command -v pi >/dev/null 2>&1; then
  version="$(pi --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  [[ "$version" == "0.84.1" ]] && ok "Pi version pinned ($version)" || warn "Pi version is ${version:-unknown}; expected 0.84.1"
fi

if [[ -f "$pi_settings" ]] && jq -e 'type == "object"' "$pi_settings" >/dev/null 2>&1; then
  ok "settings.json parses"
  [[ "$(jq -r '.defaultProjectTrust // empty' "$pi_settings")" == always ]] && ok "project trust defaults to always" || fail "defaultProjectTrust is not always"
  missing="$(jq -r '["npm:pi-subagents@0.47.1","npm:@juicesharp/rpiv-ask-user-question@2.4.0","npm:@narumitw/pi-goal@0.51.0","npm:@ff-labs/pi-fff@0.10.3","npm:pi-mcp-adapter@2.23.0","npm:pi-web-access@0.22.0"] - (.packages // []) | .[]' "$pi_settings")"
  [[ -z "$missing" ]] && ok "portable Pi package pins present" || fail "missing managed Pi package pin(s): ${missing//$'\n'/, }"
else
  fail "~/.pi/agent/settings.json missing or invalid"
fi

if [[ -x "$pi_modify" ]]; then
  synthetic='{"defaultProvider":"local","defaultModel":"keep-me","defaultThinkingLevel":"low","runtime":{"token":"keep"},"packages":["npm:pi-subagents@old","git:example/tool"]}'
  roundtrip="$(printf '%s' "$synthetic" | "$pi_modify" 2>/dev/null)"
  if jq -e '.defaultProvider=="local" and .defaultModel=="keep-me" and .defaultThinkingLevel=="low" and .runtime.token=="keep" and (.packages|index("git:example/tool")) and (.packages|index("npm:pi-subagents@0.47.1")) and .defaultProjectTrust=="always"' <<<"$roundtrip" >/dev/null 2>&1; then
    ok "modify_settings preserves runtime keys and enforces managed values"
  else
    fail "modify_settings semantic roundtrip failed"
  fi
else
  fail "Pi modify_settings source is not executable"
fi

if [[ -L "$module_bridge" ]] && [[ "$(readlink "$module_bridge")" == "npm/node_modules" ]]; then
  ok "Pi extension module bridge"
else
  fail "~/.pi/agent/node_modules must link to npm/node_modules"
fi

if [[ -f "$subagent_config" ]] && jq -e '.artifactDir=="session" and .maxSubagentDepth==4 and .maxSubagentSpawnsPerSession==0 and .asyncByDefault==true and .intercomBridge.mode=="always"' "$subagent_config" >/dev/null 2>&1; then
  ok "subagent artifacts, delegation, and coordination configured"
else
  fail "subagent config missing or inconsistent"
fi

if [[ -f "$mcp_config" ]] && jq -e '.mcpServers.blackbird.url=="http://127.0.0.1:8081" and .mcpServers.blackbird.directTools==true and .mcpServers.blackbird.toolPrefix=="none"' "$mcp_config" >/dev/null 2>&1; then
  ok "shared Blackbird MCP endpoint configured"
else
  fail "shared Blackbird MCP config missing or inconsistent"
fi

for skill in blackbird web-research; do
  [[ -f "$HOME/.agents/skills/$skill/SKILL.md" ]] && ok "shared $skill skill" || fail "shared $skill skill missing"
done

if command -v blackbird >/dev/null 2>&1; then
  bb_version="$(blackbird --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
  [[ "$bb_version" == "0.1.4" ]] && ok "Blackbird version pinned ($bb_version)" || warn "Blackbird version is ${bb_version:-unknown}; expected 0.1.4"
  command -v blackbird-claude >/dev/null 2>&1 && ok "Blackbird Claude companion installed" || fail "blackbird-claude missing"
  blackbird status >/dev/null 2>&1 && ok "Blackbird service reachable" || warn "Blackbird service not reachable — run scripts/install-agent-stack.sh"
fi

if [[ -d "$HOME/.pi/agent/npm/node_modules" ]]; then
  for spec in 'pi-subagents:0.47.1' '@juicesharp/rpiv-ask-user-question:2.4.0' '@narumitw/pi-goal:0.51.0' '@ff-labs/pi-fff:0.10.3' 'pi-mcp-adapter:2.23.0' 'pi-web-access:0.22.0'; do
    pkg="${spec%:*}"; expected="${spec##*:}"; manifest="$HOME/.pi/agent/npm/node_modules/$pkg/package.json"
    if [[ ! -f "$manifest" ]]; then warn "$pkg not installed yet"
    elif [[ "$(jq -r .version "$manifest")" == "$expected" ]]; then ok "$pkg@$expected installed"
    else warn "$pkg installed version differs from $expected"
    fi
  done
fi
