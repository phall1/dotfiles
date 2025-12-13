# AGENTS.md

This repo is a personal dotfiles setup managed with GNU Stow.

## Layout (important)

- Each top-level folder is a Stow “package” (e.g. `zsh/`, `neovim/`, `tmux/`).
- Files inside each package mirror the target paths in `$HOME`.
  - Example: `neovim/.config/nvim/init.lua` -> `~/.config/nvim/init.lua`
- Do not add files at the repo root unless they’re repo-level helpers.

## Common workflows

- Link / restow everything:
  - `./stow-all.sh`
- Dry run (no changes):
  - `./stow-all.sh -n`
- Remove all symlinks:
  - `./stow-all.sh -D`
- Full bootstrap on macOS (Homebrew + stow + deps):
  - `./install.sh`

## Neovim

- Config entrypoint: `neovim/.config/nvim/init.lua`
- Plugin manager: `lazy.nvim` (plugins declared inside `require("lazy").setup({ ... })`).
- Theme: `twenty` at `neovim/.config/nvim/colors/twenty.lua`

## Zsh

- Main config: `zsh/.zshrc`
- Modular configs: `zsh/.zsh/*.zsh`
- Secrets:
  - Put machine/user secrets in `~/.zsh_secrets` (gitignored)
  - Template: `zsh/.zsh_secrets.example`

## Conventions / safety

- Keep changes scoped to the relevant package directory.
- Avoid committing machine-specific paths or credentials.
- Prefer small, reversible edits; dotfiles breakages are painful.
