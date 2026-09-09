# CLAUDE.md

Claude Code-specific guidance for this repo. **Read AGENTS.md first** — it
covers the universal substrate. This file is the Claude-flavored supplement.

---

## What's here for you specifically

| Surface | Where | What it does |
|---|---|---|
| `/discover` skill | `dot_claude/skills/discover/SKILL.md` + `dot_local/bin/executable_claude-discover` | Run when the user asks about enabled hooks, MCP servers, experimental flags, or "what's new." Snapshots the current Claude Code surface and diffs against the last snapshot at `$XDG_STATE_HOME/dotfiles/claude/known-features.json`. |
| Shared skills | `dot_agents/skills/<name>/SKILL.md`, adapted per harness by `dot_claude/skills/<name>/symlink_SKILL.md` | One copy in `~/.agents/skills/`, symlinked into Claude, OpenCode and Hermes. `repo-onboarding`, `blackbird`, `web-research`, `cyclomatic-complexity`, `i-have-adhd`. |
| Custom agents | `dot_claude/agents/*.md` | `terminal-executor` is the only one currently tracked. Add more here, not as untracked files in `~/.claude/agents/`. |
| User settings | `dot_claude/modify_settings.json` | A chezmoi `modify_` script, **not** a copied file. It merges the portable managed keys (plugin enables, `effortLevel`, dangerous-mode) into whatever is already on disk, so `herdr`'s live hooks survive every apply. |
| Project-local permissions | `.claude/settings.local.json` (gitignored) | Per-machine, never tracked. The global `~/.config/git/ignore` enforces. |

---

## Substrate commands you can run

All live at `~/.local/bin/` post-`chezmoi apply`. All print to stdout in a form
you can read and present to the user.

```sh
dot-doctor              # health check — one file per check in checks/, exit 0/1/2
dot-doctor --list       # list all checks discovered
DOT_SKIP=zsh,claude dot-doctor   # skip specific checks
dot-bench               # perf vs PERF.md baselines (zsh-bench)
dot-audit               # drift detection (repo, submodules, brew bundle, claude features)
dot-status              # single-pane dashboard
dot-install-zsh-plugins # idempotent plugin bootstrap from plugins.lock
dot-zcompile            # zsh bytecode pre-compile (auto-runs via run_onchange hook)
claude-discover         # underlying script for the /discover skill
```

If the user asks "is my setup healthy" — run `dot-doctor` and report.
If "is anything slow" — run `dot-bench`.
If "what's new in Claude Code" — invoke the `discover` skill (or run
`claude-discover` directly if the skill isn't picking up).

Not everything on PATH is tracked here. `uv`-installed tools are managed by uv,
listed with `uv tool list`, and their source lives in whichever repo owns them:

```sh
uv tool list                          # what is installed
uv tool upgrade <name>                # or `uv tool upgrade --all`
```

**Python is always run through `uv`** — never bare `python3`, `pip`, `venv`, or
`pipx`, in scripts, docs, or workflows. A one-off script gets PEP 723 inline
metadata plus a `#!/usr/bin/env -S uv run --script` shebang; anything with a CLI
entry point becomes a package installed with `uv tool install`. When you touch a
file that still says `python3` or `pip`, convert it as part of the change.

---

## Change loop for Claude Code config

When the user asks to add a hook, MCP server, skill, or agent:

1. **Identify the right home:**
   - **Hook**: the `managed` block in `dot_claude/modify_settings.json` →
     `hooks`. Hooks are **harness-executed**, not Claude-executed — memory and
     preferences can't fulfill "automatically do X" requests. Use the
     `update-config` skill if available.
   - **MCP server**: the `managed` block → `mcpServers`.
   - **Skill**: `dot_agents/skills/<name>/SKILL.md`, plus a
     `dot_claude/skills/<name>/symlink_SKILL.md` adapter (and the equivalent
     under `dot_config/opencode/skill/` and `dot_hermes/skills/` for harnesses
     that should also see it). Claude-only skills may live at
     `dot_claude/skills/<name>/SKILL.md` — `discover` is the one example.
   - **Agent**: `dot_claude/agents/<name>.md` with frontmatter.
   - **Slash command**: `dot_claude/commands/<name>.md`.

2. **Edit in the chezmoi source (not in `~/.claude/`)**. Editing `~/.claude/`
   directly will be overwritten on next `chezmoi apply`.

   `settings.json` is reconciled by a `modify_` script, so only the keys in its
   `managed` block are enforced; everything else on disk (herdr's hooks, status
   line, project state) is preserved. Shared skills are the mirror image:
   `~/.agents/skills/` is a live preference owned by native mise history, and
   `dot_agents/skills/` only *seeds* files that are missing — an existing live
   file is never overwritten.

3. **Apply + verify:**
   ```sh
   chezmoi diff             # confirm scope
   chezmoi apply
   dot-doctor               # claude.sh proves the managed keys took and that
                            # the merge preserved everything it does not own
   ```

4. **Confirm discoverability** — run `claude-discover`. New hooks/skills/MCP
   servers should appear with 🆕 markers (since the snapshot will be stale by
   one apply).

5. **Commit** — use conventional message:
   ```
   feat(claude): add <thing> hook for <reason>
   ```

---

## The "user asks for an automatic behavior" trap

When the user says "from now on when X, do Y" or "whenever X" or "before/after X" —
that's a **hook** request. The harness executes hooks; memory and preferences
do not. If you save it as a memory, the rule will be ignored.

Use the `update-config` skill if available; otherwise add the hook to the
`managed` block in `dot_claude/modify_settings.json`, then `chezmoi apply`,
then run `claude-discover` to confirm pickup.

---

## Permissions and the project-local `.claude/`

Each project (this repo included) can have a `.claude/settings.local.json`
with **host-specific permission allowlists**. By Claude Code convention,
those files are gitignored via the global `~/.config/git/ignore`. They are
NOT tracked, NOT templated, and **must not contain anything that should
follow the user across machines** — that belongs in
`dot_claude/modify_settings.json`.

If the user wants to broaden permissions for *this* repo, edit
`~/dotfiles/.claude/settings.local.json` (gitignored, per-machine).
If they want it across all projects, add them to the `managed` block in
`dot_claude/modify_settings.json` and `chezmoi apply`.

---

## Memory: when this repo writes to your memory

The user has an active auto-memory at
`/Users/phall/.claude/projects/-Users-phall-dotfiles/memory/`. Existing memories:

- User profile (staff AI engineer, etc.) — already established.
- Feedback memories about how to engage (shaping mode, neurotic neighbor
  rigor) — already established.
- Project context (Obsidian second-brain, dotfiles refresh) — already
  established.

**When to write a NEW memory in this repo's context:**
- The user explicitly says to remember something.
- The user gives feedback you should not need twice (corrections OR explicit
  confirmations of unusual approaches).
- A non-obvious project fact that future-you would want (e.g., "the gitstatusd
  false-positive warning is intentional, ignore").

**Don't write:**
- Code patterns / file paths / architecture — readable from the repo.
- Recent activity — `git log` is authoritative.
- Anything documented in this file, AGENTS.md, or docs/.

---

## Deep review / unattended runs

`/code-review ultra` is a cloud-billed multi-agent review (`/ultrareview` is a
deprecated alias for the same thing). You cannot launch it on their behalf.
They invoke it; you don't.

For long-running unattended work (`/loop`, `/schedule`), the user has the
`loop` and `schedule` skills available. Suggest them when appropriate.

---

## Conventions specific to Claude work here

- **No emojis in committed files** unless they're decorating ASCII output in
  `dot-doctor` / `dot-bench` (where they survive only as terminal output).
- **Skill descriptions are imperatives** in the frontmatter
  (`description: Surface the current...`), not third-person.
- **Hooks are documented in their definition.** `dot_claude/modify_settings.json`
  is a shell script wrapping a JSON literal, so a `#` comment above the entry is
  the right place to explain one — no sibling `.md` needed.
- **The `/discover` skill is the canonical answer to "what's enabled?"** Use
  it; don't reinvent it.

---

## If you're new to this codebase

1. Read **AGENTS.md** (sibling file) end-to-end.
2. Read **docs/ARCHITECTURE.md** for the WHY.
3. Run **`dot-status`** to see the current state of the substrate.
4. Run **`/discover`** to see your Claude Code surface.
5. **Then** make the change.

Skip these and you'll produce work that fights the architecture.
