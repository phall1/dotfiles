# claude/

User-level Claude Code config, tracked and machine-portable.

## What's tracked

| Path | Why |
|---|---|
| `.claude/settings.json` | Plugin enables, effort level, dangerous-mode setting. Source of truth. |
| `.claude/agents/*.md` | Custom subagents (e.g. terminal-executor). |
| `.claude/skills/*/` | Custom skills (e.g. repo-onboarding). |

## What's not tracked (intentionally)

Everything else in `~/.claude/` is **state**: sessions, todos, history.jsonl,
plugins/cache, projects/, transcripts/, debug/, telemetry/. None of it belongs
in version control. Re-creating a machine recreates this from scratch.

Plugin _enablement_ lives in `settings.json` — Claude Code re-installs the
plugin from the marketplace on first use. We track the intent, not the cache.

## Install

Stowed by `stow-all.sh` (until task #7 replaces stow with chezmoi). Symlinks
the curated files into `~/.claude/`. Real state files in `~/.claude/` stay put.

## Project-local permissions

`./.claude/settings.local.json` at any repo root is **host-local** by Claude
Code convention and gitignored via the global `~/.config/git/ignore`. Not
tracked here. Each project owns its own permission list.

## Discoverability

Task #8 adds a `/discover` slash command + scheduled "what's new" job that
surfaces newly-shipped Claude Code features against a cached snapshot at
`~/.claude/state/known-features.json`. Zero post-hoc discovery friction.
