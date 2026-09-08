# AGENTS.md

**Read this before touching anything.** It exists so you can do elite work in
this repo without me holding your hand. If you violate something here, fix
the doc — don't quietly work around it.

---

## What this repo is

Personal dev substrate for one staff engineer, running on Mac (darwin/arm64)
and Raspberry Pi (linux/arm64). **Mise history** owns enrolled live preferences:
edit those in `$HOME` and its native watcher saves and synchronizes them. This
repository supplies provisioning code and first-install preference seeds.
**Chezmoi** retains machine-specific templates, executable tools and explicitly
managed application integrations. Everything is
**measured** (`dot-bench`), **checked** (`dot-doctor`), and **drift-detectable**
(`dot-audit`). The shell is treated as a substrate — every layer is observable.

This is a living organism. Local-maxima fixes get rejected.

---

## Invariants (do not violate)

1. **No hardcoded user paths in tracked files.** No `/Users/Patrick.Hall`, no
   `/Users/phall` (use `$HOME`, or chezmoi template `{{ .chezmoi.homeDir }}`).
   `dot-doctor` enforces this with a grep gate.
2. **Live `.zshenv` and its `dot_zshenv` seed stay ≤30 lines.** Every non-interactive zsh invocation pays
   its cost. Heavy init goes in `dot_zprofile` (login) or `dot_zshrc`
   (interactive). Doctor enforces.
3. **Plugins clone OUTSIDE the repo** to `$XDG_DATA_HOME/zsh/plugins/`.
   `plugins.lock` pins SHAs. Never check plugin git repos into this tree —
   that's the original-sin Pi friction we're avoiding.
4. **State stays out of source.** `~/.claude/{sessions,projects,todos,history,
   transcripts}/`, `~/.zsh_history`, `~/.zcompdump`, anything cache-shaped:
   gitignored or never copied into the chezmoi tree.
5. **Bench numbers in `PERF.md` are gates, not aspirations.** A regression
   >10% fails `dot-bench` (CI gate). Re-pin only with explicit justification
   in the commit message.
6. **Commits are scoped and bisectable.** One concern per commit. Use the
   conventional-commit style already in `git log`: `feat(scope):`,
   `perf(scope):`, `fix(scope):`, `chore:`, `refactor:`, `docs:`.
7. **Never run `git add -A` or `chezmoi apply --force` without diffing first.**
   `chezmoi diff` and `git diff --cached` are mandatory pre-flight.
8. **Startup console output goes in `~/.zsh_early` only.** It's sourced at the
   top of `dot_zshrc`, *before* the p10k instant-prompt preamble — the one safe
   place for stdout during init. Banners/MOTDs in `~/.zsh_local` (or any
   late-sourced file) print after instant prompt paints and trip p10k's
   "console output during zsh initialization" warning. Doctor enforces both the
   hook ordering and load-time hygiene of late-sourced files. Template:
   `dot_zsh_early.example`.

---

## Mental model

The initial editable preference set is in `provision/dotfiles-history.json`.
Enrollment seeds `~/.config/mise/conf.d/dotfiles-history.toml`, then that native
configuration is itself live-owned. The watcher saves into mise's bare Git
history and synchronizes with private `phall1/dotfiles-history`. Never connect
automatic history publication to this public provisioning repository.

`[data] history = true` in machine-local chezmoi configuration removes these
preferences from chezmoi ownership. Edits and intentional deletions survive
later bootstrap runs. Their `dot_*` copies are first-install seeds.

The remaining source-owned files follow this flow:

```
        edit
  ┌──────────────────┐
  │  ~/dotfiles/     │              chezmoi.toml
  │   dot_zshrc      │             (per-machine,
  │   dot_zshenv     │              outside repo)
  │   dot_config/…   │                  │
  │   dot_claude/…   │   chezmoi        │ templating data
  │   dot_local/…    │ ───apply────────►│
  │   plugins.lock   │                  ▼
  └──────────────────┘            ┌──────────────┐
       │                          │     $HOME    │
       │ run_once /               │   .zshrc     │
       │ run_onchange hooks       │   .zshenv    │
       │                          │   .config/   │
       ▼                          │   .claude/   │
   plugins                        │   .local/bin │
   ($XDG_DATA_HOME                └──────────────┘
    /zsh/plugins/)
```

**Live preference source of truth:** the paths shown by `mise bootstrap dotfiles
paths`. Edit these directly and inspect native history.
**Generated/integration source of truth:** the remaining `~/dotfiles/dot_*`
templates, modifiers and executable tools. Edit these in the repository.
**Per-machine config:** `~/.config/chezmoi/chezmoi.toml`. Lives outside the
repo. Drives templating (`{{ .git.name }}`, etc.).
**Materialized state:** `$HOME` — populated by `chezmoi apply`. Real files,
not symlinks (chezmoi's default).
**External plugins:** `$XDG_DATA_HOME/zsh/plugins/`. Cloned by
`dot-install-zsh-plugins` per `plugins.lock` SHAs.

---

## The change loop (mandatory)

Bootstrap changes must pass `mise run check`, `uv run --script
tests/bootstrap/history_test.py`, and the affected disposable
`tests/bootstrap/container.sh` architecture/profile before live workstation
apply. The default selected harness is OpenCode V2; see `docs/BOOTSTRAP.md` for
optional harnesses and application-owned service/state boundaries.

For any non-trivial change:

```sh
# 1. Baseline — capture current state.
dot-doctor    # expect: 0 failures, ≤2 warnings
dot-bench     # expect: all metrics under PERF.md baselines

# 2. Edit live-owned preferences directly; native history autosaves them.
$EDITOR ~/.zshrc
dot-zcompile
# For provisioning code/generated targets, edit their repository source instead.

# 3. Preview.
chezmoi diff
mise bootstrap dotfiles status

# 4. Apply.
chezmoi apply
# This reconciles only source-owned files after native history enrollment.

# 5. Verify.
dot-doctor    # any new failure = revert
dot-bench     # >10% regression on any pinned metric = revert OR re-pin
              # baseline with justification

# 6. Native history autosaves preferences; force an immediate checkpoint if needed.
mise bootstrap dotfiles save
# Commit repository implementation changes separately.
git add <specific files>
git commit -m "feat(zsh): add fzf-tab group preview"
```

**Baseline and post-change checks remain mandatory.** Automatic history records
edits; it does not certify correctness. Use `mise bootstrap dotfiles rollback
<path>` and `undo` for preference recovery.

---

## Repo layout (chezmoi-flat)

```
~/dotfiles/                          # this repo, == chezmoi source
├── dot_zshrc                        # → $HOME/.zshrc
├── dot_zshenv                       # → $HOME/.zshenv (≤30 lines, enforced)
├── dot_zprofile                     # → $HOME/.zprofile
├── dot_p10k.zsh                     # → $HOME/.p10k.zsh
├── dot_zsh/                         # → $HOME/.zsh/ (aliases, functions, work)
├── dot_gitconfig.tmpl               # chezmoi template → $HOME/.gitconfig
├── dot_local/bin/executable_*       # → $HOME/.local/bin/* (+x preserved)
├── dot_config/                      # → $HOME/.config/{ghostty,nvim,opencode,…}
├── dot_claude/                      # → $HOME/.claude/{settings.json,agents,skills}
├── dot_tmux.conf, dot_tmux/         # tmux
├── plugins.lock                     # SHA-pinned zsh plugins (NOT applied)
├── plugins.bin                      # binaries to symlink from plugin dirs
├── checks/                          # dot-doctor plugin dir (NOT applied)
│   ├── 00-binaries.sh                  # tool presence
│   ├── 10-repo-hygiene.sh              # grep gates
│   ├── 20-zsh-plugins.sh               # plugin SHA drift
│   ├── 30-host.sh                      # platform-specific
│   ├── zsh.sh                          # zsh-specific
│   └── claude.sh                       # claude-specific
├── scripts/
│   ├── bootstrap-darwin.sh          # one-shot host install (Mac)
│   ├── bootstrap-linux.sh           # one-shot host install (Pi)
│   ├── setup-chezmoi.sh             # interactive chezmoi.toml writer
│   └── migrate-to-chezmoi.sh        # one-time migration (preserved for posterity)
├── docs/
│   ├── setup.md                     # fresh-machine walkthrough
│   ├── ARCHITECTURE.md              # the WHY of every choice
│   └── PLAYBOOKS.md                 # per-task recipes
├── run_once_*.sh.tmpl               # chezmoi: one-time bootstrap hooks
├── run_onchange_*.sh.tmpl           # chezmoi: re-fire-on-change hooks
├── README.md
├── AGENTS.md                        # this file
├── CLAUDE.md                        # Claude Code-specific guidance
└── PERF.md                          # pinned baselines + how to investigate
```

**`dot_` is chezmoi's marker** for "this becomes a dotfile in $HOME."
**`executable_`** preserves +x. **`.tmpl`** marks a Go template.

---

## Per-task playbooks (the common operations)

These are codified in `docs/PLAYBOOKS.md`. Cheat sheet:

| Task | Where |
|---|---|
| Add a zsh plugin | Edit `plugins.lock` → `dot-install-zsh-plugins` → maybe wire into `dot_zshrc` |
| Bump a plugin to a new SHA | `cd ~/.local/share/zsh/plugins/<name> && git fetch && git checkout <sha>` → update `plugins.lock` → commit |
| Add a doctor check | Drop a file in `checks/*.sh` (or `checks/<pkg>.sh` for per-tool) using `ok`/`warn`/`fail`/`require_bin`/`want_bin` helpers. See `checks/README.md`. |
| Add a bench metric | Already plumbed — zsh-bench output is parsed by metric name. Add a `key: value_ms` pair in `PERF.md` between `BASELINE_START`/`END` markers. |
| Add a new $HOME file | Create at `dot_<name>` (or under `dot_config/<subdir>/`) in source. `chezmoi apply`. |
| Add a brew package | Edit `provision/Brewfile` (host/tap tools) or `provision/Brewfile.desktop` (GUI apps). Mise invokes real Homebrew. |
| Onboard another machine | `bash ~/dotfiles/scripts/onboard.sh` (standalone download also documented in `docs/SELF-SAVING-DOTFILES.md`); assumes base tools and GitHub login exist. |
| Provision a workstation | `mise bootstrap`; inventories and the isolated test rig are documented in `docs/BOOTSTRAP.md`. |
| Add a CLAUDE.md hook / MCP server / skill | Edit `dot_claude/settings.json` for hooks/MCP. Drop a `dot_claude/skills/<name>/SKILL.md` for a skill. Run `/discover` after to confirm pickup. |
| Add a chezmoi template variable | Add to `~/.config/chezmoi/chezmoi.toml` under `[data]`. Reference as `{{ .key }}` in a `.tmpl` file. |
| Add per-machine override | Three options in increasing specificity: chezmoi.toml per machine → hostname branch in `dot_gitconfig.tmpl` → `~/.gitconfig-work` via `includeIf`. See docs/setup.md. |
| Set up the alt git identity on a new machine | `~/dotfiles/scripts/setup-alt-identity.sh` — interactive; writes `~/.gitconfig-alt`, generates `~/.ssh/id_ed25519_alt`, runs `gh auth login` into `~/.config/gh-alt/`. Untracked outputs are per-machine. |
| Apply the alt identity to a repo | `git identity alt` (one-shot per repo: sets local `user.name`/`email` from `~/.gitconfig-alt`, rewrites origin to the `github.com-alt` SSH alias). `git identity` shows current; `git identity primary` reverts. |
| Hit the alt GitHub API | `gh-alt ...` — same surface as `gh`, but `GH_CONFIG_DIR=~/.config/gh-alt` so it always operates on the alt account regardless of `gh auth switch` state. |
| Change the shell prompt | Edit live `~/.p10k.zsh` or run `p10k configure`; native history autosaves it. Run `dot-zcompile` and `dot-bench`. |

---

## Anti-patterns (the failure modes)

- **Putting expensive init in `dot_zshenv`** — every script invocation pays.
  Use `dot_zshrc` (interactive) or `dot_zprofile` (login).
- **Touching `.zwc` files manually** — regenerated by `dot-zcompile`. Gitignored.
- **Tracking files that chezmoi materializes alongside files chezmoi doesn't** —
  pick one source-of-truth model per concern.
- **Hardcoding hostnames** — use `{{ .chezmoi.hostname }}` in templates and
  branch sparingly. Most divergence belongs in `~/.config/chezmoi/chezmoi.toml`.
- **Reinventing the doctor's wheel** — the orchestrator (`dot-doctor`) is
  intentionally dumb. New concerns are NEW files in `checks/`, not edits to
  the orchestrator.
- **Editing an enrolled preference's seed expecting a live change** — live
  preferences are authoritative. Edit `~/.zshrc`; its seed is for new installs.
- **Giving native tracking and chezmoi the same target** — doctor checks this
  ownership overlap. Generated/mixed-runtime outputs need explicit handling.
- **Committing the rendered `~/.gitconfig`** — it's machine-specific output.
  Edit `dot_gitconfig.tmpl` or `~/.config/chezmoi/chezmoi.toml` instead.
- **Adding "just for now" `set -x` / debug prints in tracked configs** — they
  always survive past "for now." Use a host-local override file.
- **Stowing-style thinking ("which package?")** — there are no packages anymore.
  The source tree mirrors `$HOME` literally with `dot_` prefixes.

---

## When to ask vs when to act

**Just act:**
- Bug fixes that don't change shape
- Adding tools to bootstrap scripts that follow the existing pattern
- Adding doctor checks (drop a file)
- Bumping plugin SHAs after verifying upstream is intentional
- Doc fixes, typos, stale path references

**Ask first:**
- Architectural changes (new dotfile manager? new prompt? new plugin loader?)
- Anything that re-pins `PERF.md` baselines (justify why)
- New tracked secrets storage approach
- New external dependency that adds to bootstrap
- New auto-running hooks (`run_once_*` / `run_onchange_*`) — they execute on
  every `chezmoi apply`
- Anything that creates an opaque convention (custom file prefix, magic env var)

When you ask, **propose a specific plan with the tradeoff** — not "what
should I do?" Show the work.

---

## Conventions

**Commit messages** — conventional + tight first line + a body that explains
the why, not the what:

```
feat(zsh): add fzf-tab group preview

git_status spikes on monorepos were burying small files in completion
output. Group preview pins the small set to the top so they stay
discoverable on a 60-line tab list.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

`feat:` new behavior. `perf:` measurable perf change. `fix:` bug. `refactor:`
no behavior change. `chore:` housekeeping. `docs:` docs only.

**File naming** — chezmoi conventions are mandatory:
- `dot_name` → `.name` in $HOME
- `executable_name` → +x preserved
- `private_name` → chmod 600
- `symlink_name` → file content is the symlink target
- `name.tmpl` → Go template, rendered at apply time

**Code style** — bash scripts: `set -uo pipefail` (not `-e` for the orchestrators;
`-euo pipefail` for one-shot scripts). zsh: prefer `[[ ]]` over `[ ]`. Comments
explain why, not what. No emojis unless decorating ASCII output.

**Python is always `uv`** — no bare `python3 foo.py`, no `pip install`, no
hand-rolled venv, no `pipx`. A single-file script carries PEP 723 inline
metadata and a `#!/usr/bin/env -S uv run --script` shebang. Anything with a CLI
entry point is a package installed with `uv tool install`, not a loose file
dropped in `dot_local/bin/`. In GitHub Actions, install uv with
`astral-sh/setup-uv` (SHA-pinned) and invoke through `uv run`. This applies
when editing existing scripts and docs too: a `python3` or `pip` reference you
touch gets converted as part of the change.

---

## Reading more

- **`docs/ARCHITECTURE.md`** — the WHY behind every choice (P10k over Starship,
  chezmoi over stow, raw zsh over antidote, mise provisioning, etc.).
- **`docs/PLAYBOOKS.md`** — full per-task recipes with exact commands.
- **`docs/setup.md`** — fresh machine bootstrap, per-machine identity layers.
- **`checks/README.md`** — doctor plugin architecture.
- **`PERF.md`** — pinned baselines, regression workflow, profiling commands.
- **`CLAUDE.md`** — Claude Code-specific guidance (skills, /discover, hooks).
- **`README.md`** — top-level orientation. Quick start.
- **Git log** — read commit messages. They explain why almost as well as the
  docs and capture in-flight context the docs don't.
