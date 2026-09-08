# Setup guide

Two hosts, one source-of-truth: Mac (darwin/arm64) and Raspberry Pi (linux/arm64).

Mise provisions tools and owns live preference history; chezmoi retains templates
and application integrations. For an existing private setup, start with
[native history adoption](SELF-SAVING-DOTFILES.md#shared-repository-and-another-machine).
The
complete inventory, profiles, service boundaries and disposable test commands
live in [BOOTSTRAP.md](BOOTSTRAP.md). OpenCode V2 is the default harness; Pi,
Claude, Hermes, Goose and Grok are optional machine selections.

## Fresh Mac

```bash
# 1. Install Xcode CLT (for git, compilers).
xcode-select --install

# 2. Clone and set identity before the first bootstrap.
git clone https://github.com/phall1/dotfiles.git ~/dotfiles
git config --global user.name 'Your Name'
git config --global user.email 'you@example.com'

# 3. Seed mise, install inventories, apply preferences, reconcile integrations.
bash ~/dotfiles/scripts/bootstrap-darwin.sh --yes

# 4. Verify.
dot-doctor
dot-bench
```

Apply triggers `run_once_install-zsh-plugins.sh.tmpl` (clones 7 plugins to
`~/.local/share/zsh/plugins/`) and `run_onchange_zcompile.sh.tmpl`
(pre-compiles zsh bytecode).

Restart your terminal or `exec zsh`.

## Fresh Raspberry Pi (Pi 4 / Pi 5, Raspberry Pi OS or Debian-based)

```bash
# 1. Clone.
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/phall1/dotfiles.git ~/dotfiles
git config --global user.name 'Your Name'
git config --global user.email 'you@example.com'

# 2. Seed mise; apt dependencies and pinned release tools replace the Nix fallback.
bash ~/dotfiles/scripts/bootstrap-linux.sh --yes --update

# 3. Verify against the documented gates.
dot-doctor
dot-bench
```

## Per-machine identity & overrides

Three knobs, increasing specificity:

### 1. Per-machine identity (`~/.config/chezmoi/chezmoi.toml`)

Lives outside the repo. Each machine has its own. Edit name/email here:

```toml
sourceDir = "~/dotfiles"
[data.git]
    name = "Patrick Hall"
    email = "phallsignup@gmail.com"
    # signingkey = "ABC123..."  # optional, enables gpgsign
```

`chezmoi apply` re-renders `~/.gitconfig` from that data.

### 2. Hostname-aware overrides (`dot_gitconfig.tmpl`)

Branch inside the template on `{{ .chezmoi.hostname }}` for anything more
than identity. Already wired in `dot_gitconfig.tmpl` — extend the empty
block when a new machine needs special handling.

### 3. Per-directory override (`~/.gitconfig-work`, untracked)

Cleanest for the work/personal split. The tracked template already has:

```gitconfig
[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work
```

To activate on a machine that has work repos:

```bash
cp ~/dotfiles/scripts/.gitconfig-work.example ~/.gitconfig-work
$EDITOR ~/.gitconfig-work    # edit email/signing key
```

Any repo under `~/work/` now uses the work identity; everything else uses
the personal one from layer 1. Zero machine-aware code paths needed.

### gh CLI auth

`~/.config/gh/hosts.yml` contains per-machine OAuth tokens. **Never tracked**
(not in chezmoi source). Each machine runs `gh auth login` once.

## Daily workflow (both hosts)

```bash
# Edit source.
$EDITOR ~/dotfiles/dot_zshrc

# Preview.
chezmoi diff

# Apply.
chezmoi apply

# (zcompile auto-runs on changes to dot_zshrc/dot_zshenv/dot_p10k.zsh.)
```

## Updating plugins

Plugins are pinned by SHA in `plugins.lock`. To bump:

```bash
cd ~/.local/share/zsh/plugins/<plugin-name>
git fetch && git checkout <new-sha>
# Update the SHA in ~/dotfiles/plugins.lock
$EDITOR ~/dotfiles/plugins.lock
# Re-bootstrap (idempotent — only touches what changed).
dot-install-zsh-plugins
git -C ~/dotfiles commit -am "chore(zsh): bump <plugin> to <short-sha>"
```

## What's NOT cross-platform

| Tool | Mac | Pi | Why |
|---|---|---|---|
| ghostty | ✓ | — | Mac-only terminal (use wezterm or default on Pi) |
| raycast | ✓ | — | Mac-only launcher |
| starship.toml | ✓ | ✓ | Tracked, but P10k replaced it (config kept for fallback) |
| Brewfile | ✓ | — | bootstrap-linux.sh uses apt+nix |
| coreutils PATH prepend | ✓ | — | Linux already has GNU coreutils |

## Troubleshooting

- **Doctor flags "settings.json diverges from source"** — run `chezmoi apply`.
- **First shell after install is slow** — instant-prompt cache hasn't been generated; restart the shell once and P10k will write the cache.
- **`first_prompt_lag` > baseline** — run `ZSH_PROF=1 zsh -i -c exit` and inspect the top of the output. The 23-line `.zshenv` is the floor; anything above that is fair game to trim.
- **`gitstatusd not running` warning in doctor** — false positive when running from a non-interactive subshell. Ignore unless an actual interactive session also has slow git status.
