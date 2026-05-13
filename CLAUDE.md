# CLAUDE.md

Claude Code-specific guidance for this repo. **Read AGENTS.md first** — it
covers the universal substrate. This file is the Claude-flavored supplement.

---

## What's here for you specifically

| Surface | Where | What it does |
|---|---|---|
| `/discover` skill | `dot_claude/skills/discover/SKILL.md` + `dot_local/bin/executable_claude-discover` | Run when the user asks about enabled hooks, MCP servers, experimental flags, or "what's new." Snapshots the current Claude Code surface and diffs against the last snapshot at `$XDG_STATE_HOME/dotfiles/claude/known-features.json`. |
| `repo-onboarding` skill | `dot_claude/skills/repo-onboarding/SKILL.md` | Read yourself in at session start. Detects stack, conventions, in-flight work. Read-only. |
| Custom agents | `dot_claude/agents/*.md` | `terminal-executor` is the only one currently tracked. Add more here, not as untracked files in `~/.claude/agents/`. |
| User settings | `dot_claude/settings.json` | Plugin enables, `effortLevel`, dangerous-mode setting. Tracked. |
| Project-local permissions | `.claude/settings.local.json` (gitignored) | Per-machine, never tracked. The global `~/.config/git/ignore` enforces. |

---

## Substrate commands you can run

All live at `~/.local/bin/` post-`chezmoi apply`. All print to stdout in a form
you can read and present to the user.

```sh
dot-doctor              # health check — 27 checks, exit 0/1/2
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

---

## Change loop for Claude Code config

When the user asks to add a hook, MCP server, skill, or agent:

1. **Identify the right home:**
   - **Hook**: `dot_claude/settings.json` → `hooks` array. Hooks are
     **harness-executed**, not Claude-executed — memory and preferences can't
     fulfill "automatically do X" requests. Use the `update-config` skill if
     available.
   - **MCP server**: `dot_claude/settings.json` → `mcpServers` object.
   - **Skill**: `dot_claude/skills/<name>/SKILL.md` with frontmatter
     (`name`, `description`). Skill body is plain markdown.
   - **Agent**: `dot_claude/agents/<name>.md` with frontmatter.
   - **Slash command**: `dot_claude/commands/<name>.md`.

2. **Edit in the chezmoi source (not in `~/.claude/`)**. Editing `~/.claude/`
   directly will be overwritten on next `chezmoi apply`.

3. **Apply + verify:**
   ```sh
   chezmoi diff             # confirm scope
   chezmoi apply
   dot-doctor               # claude.sh check verifies settings.json parses + matches source
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

Use the `update-config` skill if available; otherwise edit
`dot_claude/settings.json` directly under the `hooks` field, then
`chezmoi apply`, then run `claude-discover` to confirm pickup.

---

## Permissions and the project-local `.claude/`

Each project (this repo included) can have a `.claude/settings.local.json`
with **host-specific permission allowlists**. By Claude Code convention,
those files are gitignored via the global `~/.config/git/ignore`. They are
NOT tracked, NOT templated, and **must not contain anything that should
follow the user across machines** — that belongs in `dot_claude/settings.json`.

If the user wants to broaden permissions for *this* repo, edit
`~/dotfiles/.claude/settings.local.json` (gitignored, per-machine).
If they want it across all projects, edit `dot_claude/settings.json` and
`chezmoi apply`.

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

## Ultrareview / unattended runs

When the user invokes `/ultrareview`, it's a cloud-billed multi-agent review.
You cannot launch it on their behalf. They invoke it; you don't.

For long-running unattended work (`/loop`, `/schedule`), the user has the
`loop` and `schedule` skills available. Suggest them when appropriate.

---

## Conventions specific to Claude work here

- **No emojis in committed files** unless they're decorating ASCII output in
  `dot-doctor` / `dot-bench` (where they survive only as terminal output).
- **Skill descriptions are imperatives** in the frontmatter
  (`description: Surface the current...`), not third-person.
- **Hooks are documented in their definition** — settings.json comments are
  not supported in strict JSON, but you can leave a sibling `.md` under
  `dot_claude/` if a hook needs explaining.
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
