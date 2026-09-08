# Self-saving dotfiles

This implements the native workflow introduced in
[Dotfiles That Save Themselves](https://jdx.dev/posts/2026-09-07-dotfiles-that-save-themselves/),
using released mise **2026.9.3**.

## Everyday use

Edit the files you use: `~/.zshrc`, `~/.p10k.zsh`, Neovim configuration,
Ghostty preferences, shared skills, OpenCode commands/agents and the other
paths shown by:

```sh
mise bootstrap dotfiles paths
mise bootstrap dotfiles status
```

The native `mise-history` watcher saves quiet edits after approximately two
seconds. Automatic sharing pushes within five minutes and fetches/applies
incoming changes every fifteen minutes by default. Faster explicit convergence:

```sh
mise bootstrap dotfiles save
mise bootstrap dotfiles sync
mise bootstrap dotfiles pull
```

Saved configuration can be broken. History is recovery, not validation:
run `dot-doctor`, and run `dot-zcompile` / `dot-bench` after changing the shell.
Sync and rollback reload hooks regenerate shell bytecode after remote restores.
Caches and bytecode are excluded from history.

## Ownership

| Concern | Owner |
|---|---|
| Enrolled live preferences | Native mise history and private `phall1/dotfiles-history` |
| The live tracking configuration | `~/.config/mise/conf.d/dotfiles-history.toml`, itself tracked |
| Initial enrollment policy | `provision/dotfiles-history.json` |
| Packages, tool pins, bootstrap scripts, checks | This provisioning repository |
| Machine-specific templates, executable helpers, skill symlinks | Chezmoi source |
| Mixed runtime configs and integration registries | Native apps plus existing managed-key integration rules |
| Credentials, databases, sessions, caches and machine-local overrides | Local/application-owned; not enrolled |

The initial enrollment policy intentionally excludes `.gitconfig`, SSH config,
OpenCode's runtime/UI state, Phux's root registry, Phui's private project mapping,
and optional-harness auth/settings stores. The portable Phux layer is enrolled.
Ghostty/Cockpit/Token Tach use native macOS-only variants. Shared shell/editor
files use one portable stream across OSes.

`[data] history = true` in local chezmoi configuration removes enrolled targets
from chezmoi management. The `dot_*` copies become first-install seeds, not
mirrors to force back over live changes. Deletions stay deleted on later
bootstrap runs. `dot-doctor` checks that no live tracked preference is also a
chezmoi target.

Keep the live tracking configuration authoritative: bootstrap seeds it only
when absent, preserving subsequent native `track`, `untrack`, exclusions and
sync choices. To enroll an additional previously generated target, first remove
its chezmoi ownership, then run `mise bootstrap dotfiles track <path>`.

## Shared repository and another machine

Use private `https://github.com/phall1/dotfiles-history.git` for saved history.
This is distinct from the public provisioning source. Native history stores all
saved versions, including intermediate edits. Credentials are not enrolled.

Git, mise >=2026.9.3 and authentication for the private repository must exist on
the new machine. Configure its Git identity, then:

```sh
gh auth login
gh auth setup-git
mise bootstrap --adopt phall1/dotfiles-history
mise bootstrap dotfiles status
```

The shared global configuration declares the provisioning checkout at
`~/dotfiles`. Native repo bootstrap obtains that checkout, then its more-local
bootstrap task installs tools and renders machine-specific files. The outer
global task delegates to that task; it does not call itself recursively.
Existing source checkouts must be clean and have the expected origin. Shared
preferences are restored before chezmoi's first apply and protected immediately.

The provisioning checkout currently follows `feat/mise-workstation`; that ref
must be published before onboarding another machine. Change it deliberately in
the tracked global config when the implementation is merged.

`config.local.toml` retains native origin/auth-related local configuration.
`conf.d/zz-dotfiles-services.local.toml` retains this machine's watcher service
selection and is excluded from history. Disabling services through the machine
profile removes this watcher without deleting any checkpoints.

The watcher declaration explicitly supplies the same mise config/data/state/cache
directories used by the shell. This matters on macOS: launchd otherwise defaults
to `~/Library/Caches` while this shell uses `~/.cache`. Mise 2026.9.3 places its
history locks in the cache directory; mismatched roots split the locks even when
the history store is shared. Both native status and actual autosave are verified.

The Mac uses the official binary at `~/.local/bin/mise`; its shims were rebuilt
against that binary. Homebrew only offered 2026.9.2 at cutover. Install or update
mise to >=2026.9.3 before running these commands on another existing workstation.

## Recover an edit

```sh
mise bootstrap dotfiles history --path ~/.zshrc
mise bootstrap dotfiles rollback ~/.zshrc --dry-run
mise bootstrap dotfiles rollback ~/.zshrc
mise bootstrap dotfiles undo
```

Rollback saves current content first. Undo restores the tracked files affected
by that operation. Neither command restores packages or running application state.

For conflicting edits from two machines:

```sh
mise bootstrap dotfiles status
mise bootstrap dotfiles pull --keep-local ~/.zshrc
# Or choose the incoming version:
mise bootstrap dotfiles pull --take-remote ~/.zshrc
```

Conflicts pause publication/incoming application, while local history keeps
saving. No conflict markers are inserted into live configuration. With the
Homebrew mise build, use native status/doctor for conflict visibility; native
macOS desktop notifications require mise's signed distribution.

## Tests

`uv run --script tests/bootstrap/history_test.py` uses two isolated homes and a
local bare Git origin. It exercises real native autosave after atomic rename,
rollback, undo, fresh adoption, two-way exchange, conflict resolution and deletion.
The fixtures use canonical home paths to avoid mise 2026.9.3's history path-filter
bug with macOS `/tmp` or `/var` aliases. They never install launchd services.

`mise run check` also proves that edits and deletions survive two chezmoi applies
after enrollment on all three platform fixtures. Linux container acceptance
exercises the entire enrollment and repeat-bootstrap path.
