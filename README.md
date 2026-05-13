# dotfiles

Personal development substrate. Managed by [chezmoi](https://chezmoi.io/),
running on Mac + Raspberry Pi.

## Philosophy

The shell is the substrate. Every layer is **measured** (`dot-bench`),
**checked** (`dot-doctor`), and **drift-detectable** (`dot-audit`). Adding a
new concern is a one-file change — never edit the orchestrators.

Plugins live OUTSIDE the dotfile tree (`~/.local/share/zsh/plugins/`) so the
source repo never has to deal with nested git checkouts. Tools are
SHA-pinned (`plugins.lock`).

## Stack

| Layer | Pick | Why |
|---|---|---|
| Shell | zsh | substrate |
| Prompt | Powerlevel10k + gitstatusd | 2ms first prompt, romkatv uses it himself |
| Plugin loader | raw `source` + `zsh-defer` (no manager) | zero indirection |
| History | atuin | sqlite, fuzzy TUI |
| `cd` | zoxide | smart jump |
| Tab | fzf-tab | killer plugin |
| Python | uv | Astral, Rust |
| Node | fnm | Rust, `--use-on-cd` |
| Rust | rustup | optimal already |
| Go | `GOTOOLCHAIN=auto` | built-in |
| Env-per-dir | chpwd hook on `.env` | replaces direnv (no fork+exec) |
| Diff pager | delta | side-by-side, syntax highlight |
| Terminal (Mac) | Ghostty | Metal, native |
| Multiplexer | tmux + sesh | reliable + discoverable session picker |
| Dotfiles | chezmoi | templated, cross-host, materialized as real files |
| Secrets | age | one Go binary, X25519 |

## Layout

chezmoi-flat. Source tree mirrors `$HOME`, with `dot_` prefix replacing leading `.`:

```
~/dotfiles/                      # this repo, == chezmoi source dir
├── dot_zshrc                    # → $HOME/.zshrc
├── dot_zshenv                   # → $HOME/.zshenv  (lean — <30 lines, enforced)
├── dot_zprofile                 # → $HOME/.zprofile
├── dot_p10k.zsh                 # → $HOME/.p10k.zsh
├── dot_zsh/                     # → $HOME/.zsh/  (modular configs)
├── dot_gitconfig.tmpl           # chezmoi template, rendered to $HOME/.gitconfig
├── dot_local/bin/executable_*   # → $HOME/.local/bin/*  (+x preserved)
├── dot_config/                  # → $HOME/.config/  (ghostty, nvim, opencode, …)
├── dot_claude/                  # → $HOME/.claude/  (settings, agents, skills)
├── plugins.lock                 # SHA-pinned zsh plugins (NOT applied to $HOME)
├── plugins.bin                  # binaries to symlink from plugin dirs
├── checks/                      # dot-doctor's plugin dir (NOT applied)
├── scripts/                     # one-off scripts e.g. migrate-to-chezmoi.sh
├── run_once_*.sh.tmpl           # chezmoi: one-time bootstrap hooks
└── run_onchange_*.sh.tmpl       # chezmoi: hooks that re-run when content changes
```

## Bootstrap on a fresh machine

```bash
# 1. Clone.
git clone https://github.com/phall1/dotfiles.git ~/dotfiles

# 2. Run the host bootstrap — installs ~25 tools idempotently.
~/dotfiles/scripts/bootstrap-darwin.sh    # Mac
# or:
~/dotfiles/scripts/bootstrap-linux.sh     # Pi / Linux

# Bootstrap finishes by printing the exact next-step commands.
# In order, they are:

# 3. Configure THIS machine's git identity (interactive — prompts for name/email):
~/dotfiles/scripts/setup-chezmoi.sh

# 4. Apply dotfiles to $HOME:
chezmoi apply

# 5. Verify substrate health:
~/.local/bin/dot-doctor    # 0 failures expected
~/.local/bin/dot-bench     # perf vs PERF.md baselines
~/.local/bin/dot-audit     # drift detection
~/.local/bin/dot-status    # single-pane dashboard

# 6. Restart shell:
exec zsh
```

Apply auto-triggers `run_once_install-zsh-plugins.sh.tmpl` (clones the 7 plugins
per `plugins.lock`) and `run_onchange_zcompile.sh.tmpl` (pre-compiles bytecode
when shell source changes).

## Daily flow

```bash
# Edit source.
$EDITOR ~/dotfiles/dot_zshrc

# Apply to $HOME.
chezmoi apply

# (chezmoi auto-runs zcompile if zsh files changed.)
```

`chezmoi diff` shows what would change before apply. `chezmoi status`
shows what's diverged.

## Observability

| command | purpose |
|---|---|
| `dot-doctor` | health check. plugin-based — drop a `*.sh` in `checks/` to add a check. Exit 0/1/2 = green/warn/fail. |
| `dot-bench` | zsh-bench wrapper. Pinned baselines in `PERF.md`. Regression >10% exits nonzero. JSON archived to `~/.local/share/dotfiles/bench/`. |
| `dot-audit` | drift detection. Repo state, submodules, brew bundle, claude features delta. |
| `dot-status` | single-pane dashboard. |

## Secrets

`~/.zsh_secrets` is gitignored. Copy from `dot_zsh_secrets.example`. For
secrets that should live in the repo, use chezmoi-age:

```bash
chezmoi add --encrypt ~/.some-private-file
# Source becomes encrypted_dot_some-private-file.age
```
