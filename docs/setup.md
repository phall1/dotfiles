# Setup guide

Two hosts, one source-of-truth: Mac (darwin/arm64) and Raspberry Pi (linux/arm64).

## Fresh Mac

```bash
# 1. Install Xcode CLT (for git, compilers).
xcode-select --install

# 2. Clone the dotfiles repo to ~/dotfiles.
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles

# 3. Run the host bootstrap (installs brew + ~25 tools).
~/dotfiles/scripts/bootstrap-darwin.sh

# 4. Set up chezmoi to use ~/dotfiles as its source.
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<'EOF'
sourceDir = "~/dotfiles"
[data.git]
    name = "Your Name"
    email = "you@example.com"
EOF

# 5. Apply.
chezmoi apply

# 6. Verify.
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
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles

# 2. Run the host bootstrap (apt + nix-installed tools).
~/dotfiles/scripts/bootstrap-linux.sh

# 3. chezmoi config (same as Mac).
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<'EOF'
sourceDir = "~/dotfiles"
[data.git]
    name = "Your Name"
    email = "you@example.com"
EOF

# 4. Apply.
chezmoi apply

# 5. Verify.
dot-doctor    # some "wanted" tools may be missing on Pi (ghostty etc.) — acceptable
dot-bench     # target on Pi: first_prompt_lag < 150ms
```

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
