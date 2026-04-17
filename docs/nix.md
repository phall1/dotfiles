# Nix Notes

This dotfiles repo keeps the portable pieces of Nix configuration under version control.

## What is tracked

- `nix/.config/nix/nix.conf`
- shell initialization in `zsh/.zprofile`

The shell init tries these common profile scripts in order:

1. `/etc/profile.d/nix.sh`
2. `~/.nix-profile/etc/profile.d/nix.sh`
3. `/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`

That covers typical Determinate Nix and upstream Nix installs without hard-coding one installer.

## What is not tracked

These are machine-specific and should stay out of dotfiles:

- `/nix/receipt.json`
- `/Library/LaunchDaemons/systems.determinate.*`
- APFS volume / disk setup for the Nix store
- generated installer state under `/etc/nix` that is owned by the installer

## Reinstalling Nix

### macOS / Determinate Nix

```bash
curl -fsSL https://install.determinate.systems/nix | sh -s -- install
```

### Verify

```bash
nix --version
nix config show | grep experimental-features
```

## Applying dotfiles

After Nix is installed:

```bash
cd ~/dotfiles
./stow-all.sh
```
