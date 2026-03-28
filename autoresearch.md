# Autoresearch: opencode autoresearch plugin

## Objective
Build an OpenCode plugin that recreates the core behavior of pi-autoresearch's `/autoresearch` command.

The plugin should let OpenCode users trigger autoresearch with a slash command, persist on/off state, support `off` and `clear`, and inject autoresearch guidance back into later turns so a session can continue autonomously. It should be honest about benchmark limits and explicitly preserve the guardrail: do not overfit to the benchmark and do not cheat on the benchmark.

## Metrics
- **Primary**: score (unitless, higher is better) — capability score from `./autoresearch.sh`
- **Secondary**: duration_ms — benchmark runtime monitor only

## How to Run
`bash autoresearch.sh`

The benchmark inspects the OpenCode plugin package and command files, loads the plugin when possible, and reports:
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
- Initial session setup only.
- Plan: start with a minimal benchmarkable plugin skeleton, then add persistent state, command packaging, and system/compaction guidance hooks.
