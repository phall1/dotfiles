# Autoresearch: opencode autoresearch plugin

## Objective
Build an OpenCode plugin that recreates the core behavior of pi-autoresearch's `/autoresearch` command.

The plugin should let OpenCode users trigger autoresearch with a slash command, persist on/off state, support `off` and `clear`, and inject autoresearch guidance back into later turns so a session can continue autonomously. It should be honest about benchmark limits and explicitly preserve the guardrail: do not overfit to the benchmark and do not cheat on the benchmark.

## Metrics
- **Primary**: score (unitless, higher is better) — runtime-validity score from `./autoresearch.sh`
- **Secondary**: duration_ms — benchmark runtime monitor only

## How to Run
`bash autoresearch.sh`

The benchmark inspects the OpenCode plugin package and command files, verifies the configured plugin path actually exists on disk, loads the plugin, and checks that the custom tool shape looks compatible with the OpenCode plugin SDK. It reports:
- `METRIC score=<n>`
- `METRIC duration_ms=<n>`

## Files in Scope
- `opencode/.config/opencode/plugin/autoresearch/**` — new plugin package
- `opencode/.config/opencode/opencode.jsonc` — optional plugin registration if appropriate
- `opencode/.config/opencode/package.json` — only if needed for local development/testing

## Off Limits
- Unrelated dotfiles packages (`zsh/`, `neovim/`, `tmux/`, etc.)
- Existing third-party plugin sources unless required for compatibility inspection

## Constraints
- No benchmark cheating or hard-coding score outputs.
- Prefer a real, reviewable plugin package over prompt-only hacks.
- Keep changes scoped and reversible.
- If adding tests, they should validate behavior, not exact implementation trivia.
- The plugin should preserve the user-facing guardrail: be careful not to overfit to the benchmarks and do not cheat on the benchmarks.

## What's Been Tried
- Initial session setup created `autoresearch.md`, `autoresearch.sh`, and `autoresearch.checks.sh`.
- First plugin attempt improved the raw score but failed checks because the tests used repo-root-relative paths from inside the plugin package; discarded automatically.
- Kept implementation: added `opencode/.config/opencode/plugin/autoresearch/` with persistent `.opencode-autoresearch-state.json` handling, system/compaction hooks, an `autoresearch_manage` helper tool, tests, and config registration in `opencode/.config/opencode/opencode.jsonc`.
- Runtime validation revealed that OpenCode does **not** discover slash commands from inside the plugin package. The real command must live at `opencode/.config/opencode/commands/autoresearch.md` so it stows to `~/.config/opencode/commands/autoresearch.md`.
- Runtime validation also revealed that OpenCode 1.3.3 rejects this plugin when `index.js` exports extra named helpers; the plugin must export only the default hook factory.
- The original benchmark hit an artificial ceiling at 12 and missed important real-world failures. It was upgraded to score runtime-valid configuration and SDK-shaped tool definitions, and correctness checks now include a real OpenCode smoke test.
