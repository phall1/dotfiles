# Nix notes

This repo keeps the **portable** pieces of Nix configuration under version
control. Machine-specific installer state stays out.

## What's tracked

- `dot_config/nix/nix.conf` → applies to `~/.config/nix/nix.conf`
- Shell-side init in `dot_zprofile` (login shells only — keeps `dot_zshenv`
  lean per the substrate invariant)

The shell init probes these profile scripts in order:

1. `/etc/profile.d/nix.sh`
2. `~/.nix-profile/etc/profile.d/nix.sh`
3. `/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`

That covers Determinate Nix and upstream Nix installs without hard-coding
either.

## What's NOT tracked (deliberately)

These are machine-specific and would break on re-apply:

- `/nix/receipt.json`
- `/Library/LaunchDaemons/systems.determinate.*` (macOS)
- APFS volume / disk setup for the Nix store
- Generated installer state under `/etc/nix` owned by the installer
- Per-machine profile state (`~/.nix-profile/...` symlink chain)

## Reinstalling Nix

### macOS (Determinate)

```sh
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

### Linux / Pi

```sh
# bootstrap-linux.sh handles this for you (idempotent):
~/dotfiles/scripts/bootstrap-linux.sh

# Or manually:
curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
```

### Verify

```sh
nix --version
nix config show | grep experimental-features
```

## Re-applying dotfiles after Nix install

```sh
chezmoi apply
exec zsh
```

`dot_zprofile` will pick up the new Nix install on the next login shell.
