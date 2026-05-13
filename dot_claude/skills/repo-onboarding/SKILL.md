---
name: repo-onboarding
description: Read yourself into an unfamiliar repo at the start of a session. Detects stack, conventions, in-flight work, and surfaces a concise orientation summary. Read-only; never writes files or runs destructive commands.
---

<skill>
You are a fresh-session onboarding assistant. The user just dropped into a repo (possibly one neither of you has seen before) and wants a fast, accurate orientation: what is this codebase, what conventions does it follow, what was the last person doing, and what should I pick up?

**Hard rules:**
- READ-ONLY. Never write, edit, commit, push, stash, or run destructive commands.
- Run only the read commands listed below (or close variants). Do not execute build, test, install, or formatter commands.
- Be brief. The summary at the end should fit on one screen. Skip sections that produced no useful signal.
- Do all probes in parallel where possible. Do not narrate each step; do the work and report.

## Cross-harness note

This skill is invoked from several harnesses (Claude Code, OpenCode, Codex CLI, possibly others). The instructions are pure shell + read-tool work — no harness-specific tools required. If you are running in a harness without a structured skill loader, just follow the procedure below verbatim.

## Procedure

### 1. Identify the repo

Run these in parallel:

```bash
pwd
git rev-parse --show-toplevel 2>/dev/null
git remote -v 2>/dev/null | head -4
git branch --show-current 2>/dev/null
git log --oneline -10 2>/dev/null
git status --short 2>/dev/null
```

Note the default branch by inspecting `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null` or falling back to `main`/`master` detection from `git branch -a`.

### 2. Detect conventions and stack

List the top of the repo and probe for canonical files:

```bash
ls -la
```

Then check (with `test -e` or by reading if present, in priority order):

- **Agent instructions** (read whichever exists, in this order; stop after first hit unless they're complementary):
  - `AGENTS.md` (cross-harness standard — see https://agents.md)
  - `CLAUDE.md` (Claude Code)
  - `.cursorrules` / `.cursor/rules/` (Cursor)
  - `.github/copilot-instructions.md` (Copilot)
  - `GEMINI.md`, `.aider.conf.yml`
- **Human docs:** `README.md`, `CONTRIBUTING.md`, `docs/`, `docs/specs/`, `docs/adr/`
- **Stack manifests** (identify language + package manager):
  - Rust: `Cargo.toml`, `rust-toolchain.toml`
  - Node/TS: `package.json` (look at `scripts` and `packageManager`), `pnpm-workspace.yaml`, `turbo.json`
  - Python: `pyproject.toml`, `requirements*.txt`, `uv.lock`, `poetry.lock`
  - Go: `go.mod`
  - Ruby: `Gemfile`
  - Other: `Makefile`, `justfile`, `flake.nix`, `shell.nix`, `Dockerfile`, `docker-compose.yml`
- **CI:** `.github/workflows/` (list filenames only)
- **Task tracking conventions:**
  - **beads:** if `.beads/` directory exists AND `bd` is on PATH (`command -v bd`), run:
    - `bd ready` (top of the queue)
    - `bd list --status=in_progress` (currently in flight)
    - `bd stats` if available
    - Otherwise skip beads entirely. Do not install it.
  - **Linear:** check `.linear.toml` or `linear.toml` (skill `linear-cli` covers details)
  - **Jira/GitHub Issues:** mention if `.github/ISSUE_TEMPLATE/` or similar is present, but don't probe APIs

### 3. Inspect in-flight work

```bash
# Are we on a feature branch?
git log --oneline origin/<default>..HEAD 2>/dev/null   # commits not on default
git diff --stat                                         # unstaged
git diff --stat --staged                                # staged
git stash list 2>/dev/null
```

If the current branch name follows a convention (e.g. `cy-bead-id`, `eng-123-foo`, `feat/...`), call it out and try to correlate with beads / Linear output above.

### 4. Sanity-check the toolchain (read-only)

Only run commands that print versions / status:

```bash
# Examples — only run those relevant to the detected stack:
cargo --version 2>/dev/null
node --version 2>/dev/null
python3 --version 2>/dev/null
just --list 2>/dev/null         # safe; just enumerates recipes
make -n help 2>/dev/null || true # do NOT run actual make targets
```

Do NOT run `cargo build`, `npm install`, `pytest`, etc.

### 5. Summarize

Reply to the user with this structure (omit empty sections):

```
Repo: <name>  (<remote URL or "no remote">)
Branch: <current>  (default: <default>)
Stack: <one line — e.g. "Rust workspace, 2024 edition, no executor">

Agent instructions: <which file(s) found, 1-line gist of each>
Docs of note: <docs/specs/foo.md, ADRs, etc — only if non-obvious>

In flight:
  - <N commits ahead of default, last: "...">
  - <X modified / Y staged files; key paths>
  - <stash entries if any>

Task tracking: <beads / Linear / none>
  - <top 1-3 ready or in-progress items if available>

Best guess at current work: <one sentence, e.g. "Implementing ORDER BY lowering on branch cy-q9m; last commit propagates fields to construction sites">

Next-step suggestions: <2-3 bullets max — what to read or what to do next>
```

Keep the whole reply under ~40 lines. The user will ask follow-up questions if they want depth.

## Things to avoid

- Don't dump entire files. Quote at most a few lines.
- Don't speculate about code you didn't read. If beads is absent, just say "no beads."
- Don't run anything that mutates state, hits the network beyond `git fetch` (and even that — only if the user asks), or could be slow (`find /`, full-repo greps without scope, recursive language servers).
- Don't assume the conventions of one repo apply to another. Re-probe every time.
- Don't write a CLAUDE.md / AGENTS.md / README — that's a separate task (the `init` skill or equivalent).

## When the user wants more

After the summary, offer (one line): "Want me to read AGENTS.md / dive into <specific subsystem> / look at the most recent PR?"
</skill>
