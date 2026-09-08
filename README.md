# dotfiles

Personal workstation. Mise-provisioned, self-saving live preferences. Mac + Raspberry Pi.

Edit your enrolled dotfiles where applications read them. Native mise history
autosaves and synchronizes those edits through a private repository. Chezmoi
retains machine-specific templates and explicit integration rules.

The shell is a substrate — every layer is measured, checked, drift-detected.
Pointing an agent at this repo with a task should produce elite work without
hand-holding. Start with **`AGENTS.md`** (universal) and **`CLAUDE.md`**
(Claude-specific).

---

## Documentation map

| File | What |
|---|---|
| **[`AGENTS.md`](./AGENTS.md)** | **Read first.** Repo invariants, mental model, the change loop, conventions, anti-patterns. Universal agent briefing. |
| **[`CLAUDE.md`](./CLAUDE.md)** | Claude Code-specific guidance. Skills, hooks, `/discover`, settings layering. |
| **[`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md)** | The **why** behind every choice (P10k vs Starship, chezmoi vs stow, raw zsh vs antidote, etc.). |
| **[`docs/PLAYBOOKS.md`](./docs/PLAYBOOKS.md)** | Per-task recipes with exact commands. Adding a plugin, bumping a pin, investigating a regression. |
| **[`docs/setup.md`](./docs/setup.md)** | Fresh-machine walkthrough + per-machine identity layers. |
| **[`docs/BOOTSTRAP.md`](./docs/BOOTSTRAP.md)** | Mise inventories, profiles, installer ownership, disposable test rig and updates. |
| **[`docs/SELF-SAVING-DOTFILES.md`](./docs/SELF-SAVING-DOTFILES.md)** | Live edits, automatic history/sync, another machine, rollback and conflict recovery. |
| **[`PERF.md`](./PERF.md)** | Pinned bench baselines + how to investigate regressions. |
| **[`checks/README.md`](./checks/README.md)** | doctor's plugin-check architecture. |
| **[`docs/nix.md`](./docs/nix.md)** | Nix install + what is/isn't tracked. |
| **[`docs/IDEAS.md`](./docs/IDEAS.md)** | Half-baked ideas worth revisiting. Not commitments. |
| **`git log`** | Commit messages explain the **why** of recent changes — read it before assuming. |

---

## Stack (TL;DR)

| Layer | Pick | Source of authority |
|---|---|---|
| Shell | zsh + live `.zshrc` / `.zshenv` / `.zprofile` | Native mise history; repository copies are seeds |
| Prompt | Powerlevel10k + gitstatusd + instant-prompt | ARCHITECTURE.md §"Why P10k" |
| Plugin load | Raw `source` + `zsh-defer`, SHA-pinned via `plugins.lock` | ARCHITECTURE.md §"Why raw" |
| Shell history | Native zsh + fzf search | Live `.zshrc` |
| `cd` | zoxide | `dot_zshrc` |
| Tab | fzf-tab | `plugins.lock` |
| Bootstrap / tool versions | mise | `mise.toml`, platform/optional inventories and lockfiles |
| Python | uv | `mise.toml` |
| Node / Bun / Zig | mise | global defaults plus project pins |
| Rust | rustup | native project toolchains |
| Go | `GOTOOLCHAIN=auto` | built-in |
| Per-dir env | direnv (`.envrc`) + chpwd hook (`.env`) | `dot_zshrc` |
| Diff pager | delta | `dot_gitconfig.tmpl` |
| Terminal (Mac) | Ghostty | Live `~/.config/ghostty/config` |
| Persistent terminals | Phux + Cockpit; tmux/sesh available | `dot_config/phux`, `dot_config/phux-cockpit` |
| Agent runtime / coordination | OpenCode V2 + Blackbird | `dot_config/opencode/opencode.jsonc` |
| Git / GitHub UI | Phig + Phui | `dot_config/phig`, `dot_config/phui` |
| Preference history and sync | Native mise watcher | Private `phall1/dotfiles-history` |
| Generated files/integrations | chezmoi | Remaining `dot_*` sources and machine-local data |
| Secrets | age (via chezmoi-age) | docs/setup.md §"Secrets" |

---

## Observability (key commands)

```sh
dot-doctor        # 27-check health sweep, exit 0/1/2
dot-bench         # zsh-bench against pinned baselines, regression gate
dot-audit         # drift detection (repo / submodules / Brewfile / Claude features)
dot-status        # single-pane dashboard
```

All extensible — drop a `*.sh` in `checks/` to add a doctor check (see
`checks/README.md`).

---

## Bootstrap on a fresh machine

```sh
# 1. Clone.
git clone https://github.com/phall1/dotfiles.git ~/dotfiles

# 2. Identity (preserved in machine-local chezmoi data on first bootstrap).
git config --global user.name 'Your Name'
git config --global user.email 'you@example.com'

# 3. Seed + mise bootstrap: packages, tools, preferences and native integrations.
bash ~/dotfiles/scripts/bootstrap-darwin.sh --yes     # Mac (Xcode CLT required)
# or: bash ~/dotfiles/scripts/bootstrap-linux.sh --yes --update

# 4. Verify substrate health.
~/.local/bin/dot-doctor
~/.local/bin/dot-bench

# 5. Restart shell.
exec zsh
```

First apply installs SHA-pinned shell plugins and compiles the initial shell.
After enrollment, bootstrap and native restore hooks compile live preferences.
For an existing shared setup, follow the private-history `mise bootstrap --adopt`
instructions in [self-saving dotfiles](docs/SELF-SAVING-DOTFILES.md).

Test before applying to a workstation:

```sh
cd ~/dotfiles
mise run check
uv run --script tests/bootstrap/history_test.py
bash tests/bootstrap/container.sh linux/arm64
bash tests/bootstrap/container.sh linux/amd64
```

See [bootstrap ownership and profiles](docs/BOOTSTRAP.md) for optional harnesses,
container isolation, Mac-specific validation and update policy.

---

## Daily flow

```sh
$EDITOR ~/.zshrc                       # live preferences autosave
dot-zcompile                           # refresh shell bytecode after edits
dot-doctor                             # validate live and generated files
dot-bench                              # performance gate
mise bootstrap dotfiles status         # history, watcher and sync state
mise bootstrap dotfiles history --path ~/.zshrc
```

Edit provisioning scripts and generated-file templates in this repository,
preview with `chezmoi diff`, apply and commit those changes conventionally.

---

## Layout (chezmoi-flat)

```
~/dotfiles/                          # this repo == chezmoi source
├── dot_zshrc / dot_zshenv / dot_zprofile / dot_p10k.zsh
├── dot_zsh/                         # modular zsh configs
├── dot_gitconfig.tmpl               # chezmoi template
├── dot_local/bin/executable_*       # scripts with +x preserved
├── dot_config/                      # ghostty, nvim, opencode, sesh, …
├── dot_claude/                      # Claude Code config (settings, agents, skills)
├── dot_tmux.conf, dot_tmux/         # tmux
├── plugins.lock / plugins.bin       # SHA-pinned zsh plugins
├── checks/                          # doctor's plugin dir (NOT applied to $HOME)
├── scripts/                         # bootstrap + one-off scripts
├── docs/                            # ARCHITECTURE.md, PLAYBOOKS.md, setup.md, nix.md
├── run_once_*.sh.tmpl               # chezmoi: one-time bootstrap hooks
├── run_onchange_*.sh.tmpl           # chezmoi: re-fire-on-change hooks
├── README.md, AGENTS.md, CLAUDE.md, PERF.md
```

---

## Per-machine identity

Three layers, in order of specificity (see `docs/setup.md`):

1. `~/.config/chezmoi/chezmoi.toml` — per-machine git name/email/signing key.
2. Hostname branching in `dot_gitconfig.tmpl` — for machine-specific overrides
   beyond identity.
3. `[includeIf "gitdir:~/work/"]` → `~/.gitconfig-work` — for work/personal
   split inside a single machine.

`gh` auth (`~/.config/gh/hosts.yml`) is per-machine OAuth — never tracked.

---

## License

MIT — see `LICENSE`.
