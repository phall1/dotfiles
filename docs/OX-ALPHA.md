# Ox Alpha preview routes

Ox Alpha is an anonymous 1,048,576-token-context reasoning model currently
available at zero token price through five gateways. It is **not unlimited**:
accounts, API keys, provider rate limits, and preview availability still apply.
OpenCode and Command Code explicitly call the offer temporary; Venice calls it
beta and removable without notice. Keep normal paid/subscription models as the
defaults.

## Fast path

The tracked `ox` launcher chooses the first authenticated route in a
known-working order and reuses local OpenCode API credentials when possible.

```sh
ox status --live
ox run "implement the next scoped task and verify it"
ox ask "review this diff for correctness"              # read-only Pi posture
ox each "compare three designs for this API"           # read-only provider fanout
ox run --provider venice --harness grok "fix the test"
ox run --provider openrouter --harness codex "review HEAD"
ox run --provider opencode --harness goose --dir ~/src/app "run the tests"
```

`ox run` is mutation-capable because it uses each harness's normal posture.
`ox ask` and `ox each` use `pi-inspect`; fanout outputs are saved below
`$XDG_STATE_HOME/ox/runs/` (default `~/.local/state/ox/runs/`). This preserves
the one-writer rule while making cheap parallel review/research easy. Automatic
selection does not retry through a different gateway after dispatch: silently
crossing from a ZDR route to a retaining route would violate the privacy labels.

## Authentication

Credentials remain local. Never add them to this repository.

| Route | Environment variable | Account/key page |
|---|---|---|
| OpenCode Zen | `OPENCODE_ZEN_API_KEY` | <https://opencode.ai/auth> |
| OpenRouter | `OPENROUTER_API_KEY` | <https://openrouter.ai/keys> |
| Command Code | `COMMAND_CODE_API_KEY` | <https://commandcode.ai/studio/api-keys> |
| Nous Portal | Hermes OAuth | run `hermes portal` |
| Venice | `VENICE_API_KEY` | <https://venice.ai/settings/api> |

On this Mac, OpenRouter and Venice keys are stored in the untracked
`~/.zsh_secrets`, and Nous is connected through Hermes OAuth with Portal
Privacy Mode enabled. Venice still refuses inference at a zero account balance
even for its $0 model, so it is locally disabled and `ox` skips it. Run
`ox enable venice` after adding an eligible free balance or intentionally buying
credits. No purchase or paid subscription was made.

Run `opencode providers login` to store a key locally under the matching
configured provider. `ox` can reuse API-key entries from OpenCode or Pi without
copying the secret. `ox auth [provider]` prints the exact setup reminder.

## Endpoint and privacy matrix

| Route | Wire model ID | API root | Current privacy contract |
|---|---|---|---|
| OpenCode Zen | `x-preview-f-free` | `https://opencode.ai/zen/v1` | zero retention; no training |
| OpenRouter | `stealth/ox-alpha` | `https://openrouter.ai/api/v1` | prompts/completions retained; no training |
| Command Code | `stealth/ox-alpha` | `https://api.commandcode.ai/provider/v1` | retained; no training; Ox refuses ZDR mode |
| Nous Portal | `stealth/ox-alpha` | official: `https://inference-api.nousresearch.com/v1` | enable account Privacy Mode; metadata/exceptions remain |
| Venice | `stealth-ox-alpha` | `https://api.venice.ai/api/v1` | Venice does not log content, but upstream sees anonymized content |

Do not send private repositories or secrets through a retaining/anonymized
route merely because the model name is the same. OpenCode Zen is the preferred
route for sensitive-but-approved workloads.

Primary references:

- OpenCode Zen model, pricing, retention, and endpoint: <https://opencode.ai/docs/zen/>
- OpenRouter model and API: <https://openrouter.ai/stealth/ox-alpha>
- Command Code model/API/pricing: <https://commandcode.ai/models/ox-alpha>, <https://commandcode.ai/docs/provider>
- Nous provider catalog and privacy: <https://hermes-agent.nousresearch.com/docs/api/model-catalog.json>, <https://portal.nousresearch.com/privacy>
- Venice catalog, pricing, privacy, and beta policy: <https://api.venice.ai/api/v1/models>, <https://docs.venice.ai/overview/beta-models>

## Harness coverage

| Harness | Direct routes |
|---|---|
| Pi | all five through `~/.pi/agent/models.json` |
| OpenCode | all five; Zen/OpenRouter native plus three compatible providers |
| Hermes | Zen/OpenRouter/Nous native; Command/Venice named custom providers |
| Goose | all five declarative OpenAI-compatible providers |
| Grok Build | all five tracked custom models |
| Codex CLI | OpenRouter and Venice only, through Responses API profiles |
| Claude Code | none directly |

Claude Code requires Anthropic Messages semantics and Anthropic does not support
non-Claude models behind gateways. A translating proxy would be an unsupported,
extra dependency, so the `ox` launcher refuses that combination rather than
pretending it is reliable. Codex similarly requires Responses API; only Venice
documents this integration, while OpenRouter's Responses endpoint is beta.

Tracked provider catalogs are secret-free and preserve the normal default model
in every harness. Pi and Hermes use `modify_` merges so runtime-owned providers,
OAuth state, and selections survive `chezmoi apply`.

For non-Hermes harnesses, `ox` exposes the Nous OAuth session through Hermes's
loopback-only OpenAI-compatible proxy at `127.0.0.1:8645`; it starts the proxy
on demand and supplies only a dummy local bearer token. The real Nous credential
never leaves Hermes's auth store.
