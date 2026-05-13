# ARCHITECTURE.md

The **why** behind every choice. Read this when something doesn't make sense.
If a choice here is wrong, propose changing it — don't quietly work around it.

---

## Operating principles

1. **The shell is a substrate.** Every layer is observable, measured, and
   gated. Drift is caught before it metastasizes.
2. **Source-of-truth lives in one place.** chezmoi source files at
   `~/dotfiles/dot_*`. `$HOME` is downstream — never edit it.
3. **Living organism, not local maxima.** The doctor's check list is data,
   not code. Adding a concern is a one-file change. The bench's metric list
   grows. PERF.md baselines move with justification, never silently.
4. **Reproducibility over convenience.** SHA-pinned plugins. Deterministic
   bootstrap. The Pi and the Mac diverge in 3 controlled places, not 30.
5. **Plug-and-play across machines.** Clone → bootstrap → setup-chezmoi →
   apply. ~3 minutes start to finish. Friction here is a bug.

---

## Why P10k (Powerlevel10k), not Starship

**Decision: P10k.**

The honest measurement:

| Prompt | first_prompt_lag (ms, from zsh-bench) | git_status on monorepo |
|---|---|---|
| P10k + gitstatusd | 2 (with instant-prompt cache) | constant, ~5ms (daemon-cached) |
| Starship | 41 | 100–300ms (spikes on big repos) |
| Pure | 50–150 | sync, slow on big repos |
| agnoster | 32 | sync |

**P10k wins on two fronts Starship can't match:**

1. **Instant prompt.** P10k serializes a placeholder prompt to
   `$XDG_CACHE_HOME/p10k-instant-prompt-${USER}.zsh` on every config change,
   then sources that cache *before* the rest of zshrc runs. You see a prompt
   at the speed of `source <one file>`, not at the speed of your slowest init.
   Starship has explicitly declined to implement this
   ([discussion](https://github.com/romkatv/powerlevel10k/discussions/2607)).

2. **gitstatusd.** A persistent daemon that caches git status. On a chromium-
   sized repo, P10k stays under 20ms; Starship spikes to 100–300ms because
   it shells out to git per render. There's no clean way to wire gitstatusd
   into Starship.

**The "P10k is on life support" framing is wrong.** Romkatv's
[May 2024 statement](https://github.com/romkatv/powerlevel10k/discussions/2681):
*"It's not the kind of software that requires active maintenance just to keep
working."* He himself runs it. Finished software ≠ abandoned software.

Hand-rolled async prompt was considered and rejected as a DIY trap — you'd
spend a weekend reproducing 60% of P10k's features, worse.

---

## Why raw `source` + `zsh-defer`, not antidote / zinit

**Decision: raw zsh + zsh-defer, plugins cloned to `$XDG_DATA_HOME/zsh/plugins/`.**

The previous repo had antidote *installed* but never sourced. The plugin
manager added nothing and saved nothing. After that revelation, the question
became: do we need a plugin manager at all?

| Option | Verdict |
|---|---|
| antidote | Fine, but it's `source <file>` with extra steps. Static bundle saves nothing when you `source` 5 files yourself. |
| zinit Turbo | Faster than antidote for big plugin sets via async loading. Ugly DSL. Maintainer transitioned to zdharma-continuum fork. |
| sheldon (Rust) | Elegant, lockfile-based. No measurable speed advantage. No turbo equivalent. |
| zcomet | Honorable mention. Skipped for simplicity. |
| **Raw + `zsh-defer`** | **Zero indirection. Every line is readable. `zsh-defer` (romkatv) is 1 file, used by P10k internally. SHA-pinning via plugins.lock matches what a plugin manager would do.** |

We have 5–7 plugins. Raw wins on simplicity, transparency, and zero
maintenance surface.

**Plugins live OUTSIDE the repo** at `$XDG_DATA_HOME/zsh/plugins/`. This was
non-negotiable: stowing plugin git checkouts into `~/.zsh/plugins/` was the
original Pi friction (node_modules-like trees inside symlink trees). The
bootstrap (`dot-install-zsh-plugins`) clones to the external dir per
`plugins.lock`. Doctor verifies drift.

---

## Why chezmoi, not stow / nix home-manager / dotbot / yadm

**Decision: chezmoi.**

| Tool | Verdict |
|---|---|
| stow | Symlink farm. Worked for years but two real problems: (1) any file in a package dir gets stowed, including doc files and node_modules. (2) Cross-platform divergence requires shell-level branching, no native templating. |
| nix home-manager | Genuinely usable on Mac in 2026. Cost-to-benefit brutal for a 2-machine setup: install/uninstall complexity, slow first build, opaque errors. Reserve for fleet-scale or NixOS converts. |
| yadm | Real git repo IS your $HOME. Powerful but loose — easy to commit something private by accident. |
| dotbot | Config-file-driven symlinks. Simpler than chezmoi but doesn't template. |
| **chezmoi** | **Templating, encryption, per-host data, run_once/run_onchange hooks, `chezmoi diff` before apply. Standard shape any senior engineer recognizes.** |

The cost was the rename of ~100 files from `<pkg>/.<thing>` to `dot_<thing>`.
One-time cost. Result: declarative state, observable diffs, clean cross-host.

Materializes as **real files, not symlinks** (chezmoi default). Workflow
becomes edit-source → diff → apply, which is intentional, not accidental.

---

## Why uv / fnm / rustup / GOTOOLCHAIN, not mise

**Decision: best-in-class native per language. No meta-manager.**

`mise` tries to be everything: tool versions, env vars, task runner. Each
piece is fine, but combined it's a leaky abstraction with more surface area
than the union of:

- **uv** (Astral, Rust): Python toolchain + venv + dependency resolver.
  Orders of magnitude faster than pip+pyenv+poetry. No shims.
- **fnm** (Schniz, Rust): Node version switcher. `--use-on-cd` reads
  `.nvmrc` / `.node-version` transparently. Sub-10ms cold.
- **rustup**: optimal already. No alternative.
- **`GOTOOLCHAIN=auto`** (built-in since Go 1.21): per-`go.mod` toolchain
  download. No manager needed.

Each tool is the best at its job. The combined startup cost is lower than
mise alone. Project switching is automatic per-tool.

---

## Why a chpwd `.env` hook alongside direnv

**Decision: both.**

direnv handles `.envrc` — full bash, `direnv allow` security model. Some
repos depend on it.

The chpwd hook handles plain `.env` — sub-millisecond, no fork+exec, no
allow dance. They target different filenames and don't conflict. The chpwd
hook explicitly skips when `.envrc` is also present (no double-load).

The earlier plan was to delete direnv. Reverted when the user pointed out
some repos depend on `.envrc`. Lesson: don't optimize against a feature you
don't fully own.

---

## Why per-package check files, all in `checks/`

**Decision: `checks/<pkg>.sh` not `<pkg>/dot-checks.sh`.**

Initial design put per-package check files colocated with the package
(`zsh/dot-checks.sh`). After the chezmoi migration flattened the package
structure, there were no more package dirs. Discovery now runs glob-only
on `$DOTFILES/checks/*.sh`.

Naming convention:
- `00-*.sh`, `10-*.sh`, `20-*.sh`, `30-*.sh` — global checks, ordered.
- `<pkg>.sh` (e.g. `zsh.sh`, `claude.sh`) — per-tool checks.

Skip selection via `DOT_SKIP=zsh,claude` matches either the filename stem or
its package name.

---

## Why three layers of per-machine identity (chezmoi.toml + hostname + includeIf)

**Decision: all three. They compose.**

- **Layer 1 — `~/.config/chezmoi/chezmoi.toml`**: per-machine source of git
  name/email/signing key. Outside the repo. One source per machine.
- **Layer 2 — hostname branching in `dot_gitconfig.tmpl`**: for divergence
  beyond identity (custom ssh command, alternate pager). Single template,
  multiple outputs.
- **Layer 3 — `[includeIf "gitdir:~/work/"]`**: per-directory override on a
  single machine for work/personal split. The override file
  (`~/.gitconfig-work`) is untracked.

These cover the three real failure modes: different identities per machine,
machine-specific quirks, and project-context-specific overrides. None
sufficient alone.

---

## Why doctor/bench/audit/status, not a single `dot-health`

**Decision: four commands, each with one clear job.**

- **`dot-doctor`**: instantaneous health snapshot. Are the tools present?
  Do the configs parse? Are there hardcoded paths? Exit 0/1/2.
- **`dot-bench`**: perf measurement only. Gates regressions against pinned
  baselines. Writes archival JSON for trend.
- **`dot-audit`**: drift detection only. Repo state, submodule SHAs, brew
  bundle, claude features delta.
- **`dot-status`**: read-only aggregate dashboard. Reads cached state from
  the other three. The "is my house in order" check.

Splitting them keeps each composable and CI-friendly. A single command would
either run too slow (combine all) or hide signal (subset only).

---

## Why `dot-doctor` is a thin orchestrator

**Decision: orchestrator stays dumb; checks are data.**

The orchestrator (`dot-doctor`) does one thing: discover `checks/*.sh` and
source each. Helpers (`ok`/`warn`/`fail`/`require_bin`/`want_bin`/`hdr`/
`file_age_h`) are exported so check files are tiny.

This is the **living organism** principle in code. Adding a substrate
concern = drop a file. The orchestrator never grows. The day someone has to
edit `dot-doctor` to add a check is the day this architecture failed.

---

## Why first_prompt_lag floor of ~46ms (and what's not optimized away)

**Decision: 46ms is acceptable. Going lower requires lazy-Nix.**

The breakdown:
- ~5ms: zsh fork + base init
- ~30ms: `.zprofile` sourcing (Nix init when env wasn't inherited)
- ~5ms: `dot_zshrc` pre-prompt code (PATH adds, plugin sourcing)
- ~5ms: P10k startup overhead + first prompt render

Instant-prompt makes the placeholder appear quickly — but the *measured*
`first_prompt_lag_ms` is to the first prompt, and our floor is dominated by
Nix init. To push below 40ms, we'd need to lazy-load Nix (function wrapper
that expands env on first invocation). Not done — Nix init is correct and
the marginal benefit isn't worth the complexity.

Re-evaluate if first_prompt_lag becomes user-visible (>100ms feels laggy).
Today it doesn't.

---

## What we explicitly rejected

| Option | Rejected because |
|---|---|
| Hand-rolled async zsh prompt | DIY trap. P10k already solves it. |
| z4h (zsh-for-humans) | Prescriptive whole-shell. We want to own the load layer. |
| oh-my-zsh / prezto | Bloated. Most useful pieces already in our 7 plugins. |
| thefuck | Slow, gimmicky. Doesn't pass the neurotic filter. |
| mise | Tries to be too many things. |
| Stow continued | See "Why chezmoi". |
| Submodules for plugins | They worked, but `chezmoi externals` is forward-compatible and `plugins.lock` is the equivalent without `git submodule update --init` UX wart. |
| Single mega-config file | The modular `dot_zsh/*.zsh` split is worth the indirection — aliases, functions, work are different concerns. |
| Symlink mode for chezmoi | Materialize-as-symlinks is closer to stow but loses the "apply is intentional" property. Copy mode wins for elite discipline. |

---

## Open questions

These don't have settled answers yet. Document them when you decide.

- **zellij vs tmux**: zellij is the modern challenger (discoverable keys,
  Rust, KDL). tmux has the plugin ecosystem. Currently tmux + sesh.
  Re-evaluate when zellij plugin maturity catches up.
- **Lazy-loading Nix**: see "first_prompt_lag floor." Worth it iff we hit
  100ms+ on Pi.
- **Auto-bumping plugin SHAs**: a `bin/dot-update-pins` that fetches each
  pin's HEAD and shows a diff for review. Manual today; automation when
  motivated.
- **CI**: GitHub Actions running `dot-doctor` + `dot-bench` on every PR.
  Not yet — substrate is small enough to verify locally.
- **Brewfile**: bootstrap-darwin.sh hardcodes the package list. Could be a
  proper Brewfile checked in. Today's list is short enough to not bother.

---

## How to update this doc

When you change architecture, update this doc *in the same commit*. The
test: a new agent reading this six months from now should understand
**why** the current shape exists, not just **what** it is. If your change
makes the doc's reasoning wrong, the doc must change too.
