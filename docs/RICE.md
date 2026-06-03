# RICE.md

macOS "ricing" stack — tiling WM, hotkeys, status bar, window borders.
**Open this file first when changing anything visual about the desktop.**

For Claude iterating later: this doc is the index. Every "change X" recipe
points at the specific file + line region. Edit the chezmoi source under
`~/dotfiles/dot_config/`, never `~/.config/` directly.

---

## What's installed

| Tool | Role | Tap | Service |
|---|---|---|---|
| [yabai](https://github.com/asmvik/yabai) | Tiling window manager (bsp) | `koekeishiya/formulae` | `yabai --start-service` |
| [skhd-zig](https://github.com/jackielii/skhd.zig) | Hotkey daemon (drives yabai) | `jackielii/tap` | `skhd --install-service && skhd --start-service` |
| [sketchybar](https://github.com/FelixKratz/SketchyBar) | Custom status bar | `FelixKratz/formulae` | `brew services start sketchybar` |
| [JankyBorders](https://github.com/FelixKratz/JankyBorders) | Colored window borders | `FelixKratz/formulae` | `brew services start borders` |

> **skhd note:** the original [koekeishiya/skhd](https://github.com/koekeishiya/skhd) is in maintenance mode and points users at the Zig rewrite [`skhd.zig`](https://github.com/jackielii/skhd.zig). We use the rewrite — same config syntax (`skhdrc` is drop-in compatible), actively maintained, and **auto-reloads on config change** (no `skhd --restart-service` needed after edits).

Fonts: `font-jetbrains-mono-nerd-font` (icons + text), `font-sketchybar-app-font` (app glyphs).

Install everything from scratch: `~/dotfiles/scripts/bootstrap-darwin.sh`.

---

## File → responsibility map

| File (source) | Materializes to | Controls |
|---|---|---|
| `dot_config/yabai/executable_yabairc` | `~/.config/yabai/yabairc` | Tiling layout, gaps, padding, mouse behavior, float rules, signals to sketchybar |
| `dot_config/skhd/skhdrc` | `~/.config/skhd/skhdrc` | All keyboard shortcuts (focus, swap, resize, space switch, launchers) |
| `dot_config/sketchybar/executable_sketchybarrc` | `~/.config/sketchybar/sketchybarrc` | Bar layout, colors, fonts, which items render |
| `dot_config/sketchybar/plugins/executable_*.sh` | `~/.config/sketchybar/plugins/*.sh` | Per-item update logic (space dots, clock, battery, volume, front_app) |
| `dot_config/borders/executable_bordersrc` | `~/.config/borders/bordersrc` | Border width, active/inactive colors |
| `scripts/bootstrap-darwin.sh` | (not applied) | Brew taps + package list for fresh-machine install |

---

## Common edits (the cheat sheet)

### Change the color palette
The desktop chrome uses the same Blackwater Rust palette as Ghostty, Neovim, and the shell prompt. Search and replace these hex codes across `dot_config/{ghostty,nvim,sketchybar,borders}/` and `dot_p10k.zsh`:

| Role | Current | Where it lives |
|---|---|---|
| Bar background | `0xee071012` | `sketchybarrc` `--bar` color |
| Item surface | `0xff111b1f` | `sketchybarrc` default pill backgrounds |
| Foreground text | `0xffc5d0cd` | `sketchybarrc` defaults + plugin scripts |
| Accent (active space, border, apple) | `0xff45d0bd` | `sketchybarrc` + `bordersrc` `active_color` |
| Dim (inactive border, inactive space) | `0xff1d3035` / `0xff60706e` | `bordersrc` `inactive_color` + `space.sh` |
| Battery green/yellow/red | `7fae8b` / `d6a84f` / `e45f57` | `plugins/battery.sh` |

Core palette roles:
- **Blackwater**: bg=`071012`, bg_dark=`05090b`, bg_light=`111b1f`, selection=`1d3035`
- **Text**: fg=`c5d0cd`, bright=`e6efeb`, comment=`60706e`, dim=`425250`
- **Signal**: teal=`45d0bd`, blue=`6f9fbd`, green=`7fae8b`, violet=`9b8ac5`
- **Rust**: amber=`d6a84f`, copper=`c27a4a`, coral=`e45f57`

### Change the modifier key
`alt` is used everywhere in `skhd/skhdrc`. To swap to `cmd + alt`:
```sh
sed -i '' 's/^alt -/cmd + alt -/; s/^shift + alt -/shift + cmd + alt -/' \
  ~/dotfiles/dot_config/skhd/skhdrc
chezmoi apply && skhd --restart-service
```

### Adjust gaps / padding
`dot_config/yabai/executable_yabairc` lines ~16-20. Bump values, then:
```sh
chezmoi apply && yabai --restart-service
```

### Add/remove a space indicator
Spaces 1-9 are auto-rendered in `sketchybarrc` (the `SPACE_ICONS` loop).
Reduce/extend the array. Match the count to macOS Mission Control spaces.

### Add a status bar item
1. New plugin script: `dot_config/sketchybar/plugins/executable_<name>.sh`
2. Register it in `sketchybarrc` with `--add item <name> right` (or `left`) and `--set <name> script="$PLUGIN_DIR/<name>.sh"`
3. `chezmoi apply && sketchybar --reload`

### Float a new app
Add a rule near the bottom of `yabairc`:
```sh
yabai -m rule --add app="^MyApp$" manage=off
```

### Change clock format
`plugins/executable_clock.sh` — edit `DATE_FMT` (`man strftime`).

---

## Reload commands

```sh
yabai --restart-service        # after editing yabairc
# skhd-zig auto-reloads on edit — no manual reload needed for skhdrc changes.
sketchybar --reload            # after editing sketchybarrc or plugins
~/.config/borders/bordersrc     # after editing bordersrc

# Or just restart everything (also bound to ctrl+alt+cmd+r via skhd):
yabai --restart-service && skhd --restart-service && \
  sketchybar --reload && ~/.config/borders/bordersrc
```

To start fresh after install:
```sh
yabai --start-service
skhd --start-service
brew services start sketchybar
brew services start borders
```

---

## SIP upgrade path (optional but recommended)

Without partial-SIP-disable, this rice still works — tiling, hotkeys, bar, borders all functional. What you LOSE:

- **Cross-space window move** (`shift+alt+1..9`) — focus moves, window stays put
- **Window opacity** (inactive windows fading)
- **Window animations**
- **Window shadows control**

To unlock all of these, partially disable SIP:

1. Boot into recovery mode: shut down → hold power until "Loading startup options" → Options → Continue.
2. From recovery, open Terminal (Utilities menu).
3. Run:
   ```sh
   csrutil enable --without fs --without debug --without nvram
   ```
4. (Apple Silicon only) Set boot policy:
   ```sh
   csrutil authenticated-root disable
   ```
5. Reboot normally.
6. Allow yabai's scripting addition (one-time, after reboot):
   ```sh
   sudo yabai --install-sa
   sudo yabai --load-sa
   ```
7. Uncomment the `[SIP]` blocks in `yabairc` (lines marked `# yabai -m config window_*`).
8. `chezmoi apply && yabai --restart-service`.

Full procedure with screenshots: https://github.com/asmvik/yabai/wiki/Disabling-System-Integrity-Protection

---

## Permissions

macOS will prompt for Accessibility + Screen Recording when yabai and skhd first start. Grant both:
- **System Settings → Privacy & Security → Accessibility** → enable `yabai`, `skhd`
- **System Settings → Privacy & Security → Screen Recording** → enable `yabai`, `sketchybar`

If you miss the prompt, manually add the binaries (their paths: `which yabai`, `which skhd`, `which sketchybar`).

After granting, restart the services.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Hotkeys don't fire | `skhd --start-service`. Check Accessibility permission. |
| Windows don't tile | `yabai --start-service`. Check Accessibility. Some apps (e.g. System Settings) are intentionally `manage=off`. |
| Bar is invisible | `brew services restart sketchybar`. Confirm Screen Recording permission. Check `~/Library/LaunchAgents/homebrew.mxcl.sketchybar.plist` exists. |
| Bar shows boxes instead of icons | JetBrains Mono Nerd Font / sketchybar-app-font not installed: `brew install --cask font-jetbrains-mono-nerd-font font-sketchybar-app-font`, then `sketchybar --reload`. |
| Borders don't appear | `brew services start borders`. Check Screen Recording permission for `borders`. |
| Logs | `tail -f /tmp/yabai_$USER.out.log`, `tail -f /tmp/skhd_$USER.out.log`, `brew services info sketchybar` |
| Reset everything | `yabai --uninstall-sa` (if SIP disabled), `brew services stop yabai skhd sketchybar borders`, then re-bootstrap. |

---

## System-wide mutations log

Anything this rice setup changes **outside the repo** (macOS defaults,
permissions, launchd, etc.) is tracked in [`docs/REVERSIBLES.md`](./REVERSIBLES.md)
with apply + revert commands. Already logged: macOS menu bar auto-hide.

When making a new system mutation (e.g., enabling SIP partial-disable, tweaking
another `defaults` key), add an entry there too.

---

## How Claude should iterate on this

1. Read this file first.
2. Edit chezmoi source under `~/dotfiles/dot_config/<tool>/`, never `~/.config/`.
3. `chezmoi diff` to preview.
4. `chezmoi apply`.
5. Reload the affected service (table above).
6. If the change visibly works, commit with `feat(rice): <what>` or `style(rice): <what>`.

Don't edit `~/.config/` directly — `chezmoi apply` will overwrite it.
Don't add new tools without updating `scripts/bootstrap-darwin.sh`.
Don't introduce new top-level conventions — extend the `dot_config/<tool>/` pattern.
