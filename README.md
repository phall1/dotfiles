# dotfiles

Personal dev substrate. chezmoi-managed. Mac + Raspberry Pi.

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
| **[`PERF.md`](./PERF.md)** | Pinned bench baselines + how to investigate regressions. |
| **[`checks/README.md`](./checks/README.md)** | doctor's plugin-check architecture. |
| **[`docs/nix.md`](./docs/nix.md)** | Nix install + what is/isn't tracked. |
| **[`docs/IDEAS.md`](./docs/IDEAS.md)** | Half-baked ideas worth revisiting. Not commitments. |
| **`git log`** | Commit messages explain the **why** of recent changes — read it before assuming. |

---

## Stack (TL;DR)

| Layer | Pick | Source of authority |
|---|---|---|
| Shell | zsh + `dot_zshrc` / `dot_zshenv` / `dot_zprofile` | ARCHITECTURE.md §"substrate" |
| Prompt | Powerlevel10k + gitstatusd + instant-prompt | ARCHITECTURE.md §"Why P10k" |
| Plugin load | Raw `source` + `zsh-defer`, SHA-pinned via `plugins.lock` | ARCHITECTURE.md §"Why raw" |
| History | atuin | `dot_zshrc` |
| `cd` | zoxide | `dot_zshrc` |
| Tab | fzf-tab | `plugins.lock` |
| Python | uv | bootstrap-darwin.sh |
| Node | fnm (`--use-on-cd`) | `dot_zshrc` |
| Rust | rustup | bootstrap-darwin.sh |
| Go | `GOTOOLCHAIN=auto` | built-in |
| Per-dir env | direnv (`.envrc`) + chpwd hook (`.env`) | `dot_zshrc` |
| Diff pager | delta | `dot_gitconfig.tmpl` |
| Terminal (Mac) | Ghostty | `dot_config/ghostty/config` |
| Multiplexer | tmux + sesh | `dot_tmux.conf`, `dot_config/sesh/sesh.toml` |
| Dotfile manager | chezmoi | `~/.config/chezmoi/chezmoi.toml` |
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

# 2. Host bootstrap (installs ~25 tools idempotently, ends with next-step
#    instructions).
~/dotfiles/scripts/bootstrap-darwin.sh     # Mac
~/dotfiles/scripts/bootstrap-linux.sh      # Pi / Linux

# 3. Per-machine identity (interactive — prompts for git name/email/key).
~/dotfiles/scripts/setup-chezmoi.sh

# 4. Apply dotfiles to $HOME.
chezmoi apply

# 5. Verify substrate health.
~/.local/bin/dot-doctor
~/.local/bin/dot-bench

# 6. Restart shell.
exec zsh
```

Apply auto-triggers `run_once_install-zsh-plugins.sh.tmpl` (clones plugins per
`plugins.lock`) and `run_onchange_zcompile.sh.tmpl` (pre-compiles bytecode
when shell sources change).

---

## Daily flow

```sh
$EDITOR ~/dotfiles/dot_zshrc           # source of truth lives in ~/dotfiles
chezmoi diff                           # preview
chezmoi apply                          # propagate to $HOME
dot-doctor                             # verify
dot-bench                              # verify perf
git commit -m "feat(zsh): ..."         # conventional commits
```

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
