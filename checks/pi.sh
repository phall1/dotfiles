# Pi agent-stack checks. Runtime-owned state is inspected, never reconciled here.

hdr "pi agent stack"

pi_settings="$HOME/.pi/agent/settings.json"
pi_modify="$DOTFILES/dot_pi/private_agent/modify_settings.json"
subagent_config="$HOME/.pi/agent/extensions/subagent/config.json"
goal_config="$HOME/.pi/agent/pi-goal.json"
module_bridge="$HOME/.pi/agent/node_modules"
mcp_config="$HOME/.config/mcp/mcp.json"

if command -v pi >/dev/null 2>&1; then
  version="$(pi --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  pi_pin="$(sed -n 's/^PI_VERSION=//p' "$DOTFILES/scripts/install-agent-stack.sh" | head -1)"
  if [[ -n "$pi_pin" && "$version" == "$pi_pin" ]]; then
    ok "Pi matches the installer pin ($version)"
  else
    warn "Pi is ${version:-unknown}; scripts/install-agent-stack.sh pins ${pi_pin:-unknown}"
  fi
fi

if command -v node >/dev/null 2>&1 && node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit(major > 22 || (major === 22 && minor >= 19) ? 0 : 1)' >/dev/null 2>&1; then
  ok "Node satisfies Pi runtime floor ($(node --version))"
else
  fail "Pi 0.84.x requires Node >=22.19.0"
fi

if [[ -f "$pi_settings" ]] && jq -e 'type == "object"' "$pi_settings" >/dev/null 2>&1; then
  ok "settings.json parses"
  [[ "$(jq -r '.defaultProjectTrust // empty' "$pi_settings")" == always ]] && ok "project trust defaults to always" || fail "defaultProjectTrust is not always"
  missing="$(jq -r '["npm:pi-subagents@0.47.1","npm:@narumitw/pi-goal@0.51.0","npm:@ff-labs/pi-fff@0.10.3","npm:pi-mcp-adapter@2.23.0","npm:pi-web-access@0.22.0","npm:@osolmaz/pi-workflows@0.13.4"] - (.packages // []) | .[]' "$pi_settings")"
  [[ -z "$missing" ]] && ok "portable Pi package pins present" || fail "missing managed Pi package pin(s): ${missing//$'\n'/, }"
  if jq -e '[(.packages // [])[] | if type == "object" then .source else . end | select(type == "string" and test("rpiv-ask-user-question"))] | length == 0' "$pi_settings" >/dev/null 2>&1; then
    ok "user-question package absent"
  else
    fail "retired user-question package is still configured"
  fi
else
  fail "~/.pi/agent/settings.json missing or invalid"
fi

if [[ -x "$pi_modify" ]]; then
  synthetic='{"defaultProvider":"local","defaultModel":"keep-me","defaultThinkingLevel":"low","runtime":{"token":"keep"},"packages":["npm:pi-subagents@old","npm:@juicesharp/rpiv-ask-user-question@2.4.0","git:example/tool"]}'
  roundtrip="$(printf '%s' "$synthetic" | "$pi_modify" 2>/dev/null)"
  if jq -e '.defaultProvider=="local" and .defaultModel=="keep-me" and .defaultThinkingLevel=="low" and .runtime.token=="keep" and (.packages|index("git:example/tool")) and (.packages|index("npm:pi-subagents@0.47.1")) and (.packages|index("npm:@osolmaz/pi-workflows@0.13.4")) and ((.packages|map(tostring)|map(contains("rpiv-ask-user-question"))|any) | not) and .subagents.watchdog.enabled==true and .subagents.watchdog.main.enabled==true and .defaultProjectTrust=="always"' <<<"$roundtrip" >/dev/null 2>&1; then
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

if [[ -f "$pi_settings" ]] && jq -e '.subagents.watchdog.enabled==true and .subagents.watchdog.main.enabled==true and .subagents.watchdog.children.enabled==false and .subagents.watchdog.autoFollow.blockers==true and .subagents.watchdog.autoFollow.maxAttempts==2 and .subagents.watchdog.autoFollow.stalemateRepeats==2' "$pi_settings" >/dev/null 2>&1; then
  ok "main-session adversarial watchdog configured"
else
  fail "subagent watchdog config missing or inconsistent"
fi

if [[ -f "$goal_config" ]] && jq -e '.toolVisibility=="always" and .experimental.goals==true and .rpc.enabled==false and .continuationLimits.automaticTurns==100 and .continuationLimits.noProgressTurns==3' "$goal_config" >/dev/null 2>&1; then
  ok "autonomous goal continuation configured"
else
  fail "pi-goal config missing or inconsistent"
fi

if [[ -f "$mcp_config" ]] && jq -e '.mcpServers.blackbird.url=="http://127.0.0.1:8081" and .mcpServers.blackbird.directTools==true and .mcpServers.blackbird.toolPrefix=="none"' "$mcp_config" >/dev/null 2>&1; then
  ok "shared Blackbird MCP endpoint configured"
else
  fail "shared Blackbird MCP config missing or inconsistent"
fi

for skill in blackbird web-research cyclomatic-complexity; do
  [[ -f "$HOME/.agents/skills/$skill/SKILL.md" ]] && ok "shared $skill skill" || fail "shared $skill skill missing"
done

complexity_skill="$HOME/.agents/skills/cyclomatic-complexity/SKILL.md"
for adapter in \
  "$HOME/.claude/skills/cyclomatic-complexity/SKILL.md" \
  "$HOME/.config/opencode/skill/cyclomatic-complexity/SKILL.md" \
  "$HOME/.hermes/skills/cyclomatic-complexity/SKILL.md"
do
  if [[ -L "$adapter" && "$adapter" -ef "$complexity_skill" ]]; then
    ok "cyclomatic-complexity adapter: ${adapter#"$HOME"/}"
  else
    fail "cyclomatic-complexity adapter missing or stale: ${adapter#"$HOME"/}"
  fi
done

if command -v blackbird >/dev/null 2>&1; then
  # The expected version is read from the installer rather than repeated here;
  # the two drifted apart once already.
  bb_version="$(blackbird --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
  bb_pin="$(sed -n 's/^BLACKBIRD_VERSION=//p' "$DOTFILES/scripts/install-agent-stack.sh" | head -1)"
  if [[ -n "$bb_pin" && "$bb_version" == "$bb_pin" ]]; then
    ok "Blackbird matches the installer pin ($bb_version)"
  else
    warn "Blackbird is ${bb_version:-unknown}; scripts/install-agent-stack.sh pins ${bb_pin:-unknown}"
  fi
  # blackbird doctor supersedes the per-binary probes: the Go companions stopped
  # shipping in v0.3.0, and doctor checks the service definition, a real daemon
  # handshake, and the database. It exits 5 when a check fails and 0 otherwise,
  # so warnings stay advisory unless --strict is passed.
  bb_rc=0; blackbird doctor >/dev/null 2>&1 || bb_rc=$?
  if (( bb_rc == 0 )); then
    ok "Blackbird doctor reports no failures"
  else
    fail "Blackbird doctor reports failures — run: blackbird doctor"
  fi
fi

if [[ -d "$HOME/.pi/agent/npm/node_modules" ]]; then
  for spec in 'pi-subagents:0.47.1' '@narumitw/pi-goal:0.51.0' '@ff-labs/pi-fff:0.10.3' 'pi-mcp-adapter:2.23.0' 'pi-web-access:0.22.0' '@osolmaz/pi-workflows:0.13.4'; do
    pkg="${spec%:*}"; expected="${spec##*:}"; manifest="$HOME/.pi/agent/npm/node_modules/$pkg/package.json"
    if [[ ! -f "$manifest" ]]; then warn "$pkg not installed yet"
    elif [[ "$(jq -r .version "$manifest")" == "$expected" ]]; then ok "$pkg@$expected installed"
    else warn "$pkg installed version differs from $expected"
    fi
  done
fi
