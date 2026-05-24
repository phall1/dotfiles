# RICE-CHEATSHEET.md

Day-to-day keybinds + ops for the yabai/skhd/sketchybar/borders stack.
For *changing* the rice, see [`RICE.md`](./RICE.md). For *system mutations
made*, see [`REVERSIBLES.md`](./REVERSIBLES.md).

> `alt` = Option (⌥) · `cmd` = Command (⌘) · `ctrl` = Control (⌃) · `shift` = ⇧

---

## Mental model (read once)

- **yabai** auto-tiles your windows in a binary tree (one window splits into
  two, two split into four, etc.). It only manages windows opened *after* it
  started. New windows always land "next to" the focused window.
- **skhd** listens for keychords and runs yabai commands.
- **sketchybar** is the top bar (apple, space dots, app name, clock, battery,
  volume). Independent of yabai but visually wired up.
- **borders** paints a colored outline around the focused window so you
  always know which one will receive keys.

You can ignore all this and just open windows — they tile automatically.

---

## The 10 keybinds you'll actually use

| Chord | Action |
|---|---|
| `alt + return` | New Ghostty terminal |
| `alt + h / j / k / l` | Focus left / down / up / right |
| `shift + alt + h/j/k/l` | **Swap** focused window with neighbor |
| `alt + f` | Zoom focused window to fill space (toggle) |
| `alt + r` | Rotate layout 90° (side-by-side ↔ stacked) |
| `alt + e` | Balance all splits equally |
| `alt + t` | Toggle floating (escape hatch from tiling) |
| `alt + 1 .. 9` | Focus space N |
| `shift + alt + 1 .. 9` | Send focused window to space N *(SIP-only)* |
| `ctrl + alt + cmd + r` | Restart everything (yabai + skhd + sketchybar + borders) |

That's the muscle-memory set. Everything below is for when you want more.

---

## Full keymap reference

### Focus
| Chord | Action |
|---|---|
| `alt + h` | Focus window west |
| `alt + j` | Focus window south |
| `alt + k` | Focus window north |
| `alt + l` | Focus window east |

### Move (swap positions, tree stays same)
| Chord | Action |
|---|---|
| `shift + alt + h/j/k/l` | Swap focused window with neighbor in that direction |

### Warp (reshape the tree, more aggressive than swap)
| Chord | Action |
|---|---|
| `ctrl + alt + h/j/k/l` | Move + reinsert focused window into target container |

> **Swap vs warp**: swap exchanges two windows' positions. Warp moves a
> window *out of its branch* and into a new one — useful when the tree
> structure is wrong, not just the order.

### Resize
| Chord | Action |
|---|---|
| `alt + left` | Shrink horizontally (40px) |
| `alt + right` | Grow horizontally (40px) |
| `alt + up` | Shrink vertically (40px) |
| `alt + down` | Grow vertically (40px) |

### Window state
| Chord | Action |
|---|---|
| `alt + f` | Zoom fullscreen (yabai-managed — keeps tiling) |
| `shift + alt + f` | Native macOS fullscreen (new space, leaves tiling) |
| `alt + t` | Float — pulls window out of tiling, centers it |
| `alt + p` | Pin on top (sticky + topmost) |

### Layout
| Chord | Action |
|---|---|
| `alt + r` | Rotate layout 90° |
| `alt + y` | Mirror Y axis (flip horizontally) |
| `alt + x` | Mirror X axis (flip vertically) |
| `alt + e` | Equalize all splits |
| `alt + s` | Toggle split orientation (vertical ↔ horizontal) |

### Spaces
| Chord | Action |
|---|---|
| `alt + 1 .. 9` | Focus space N |
| `shift + alt + 1 .. 9` | Send focused window to space N **(needs SIP off)** |

Spaces are macOS-native. Create them via Mission Control (3-finger swipe up,
then `+`). yabai tiles within whatever spaces macOS gives you.

### Mouse
| Action | Result |
|---|---|
| `fn + left-drag` window | Move window freely (overrides tiling) |
| `fn + right-drag` window | Resize window |
| Drop window onto another | **Swap** their positions |
| Click sketchybar space dot | Focus that space |

### Service controls
| Chord | Action |
|---|---|
| `ctrl + alt + cmd + r` | Restart yabai + skhd + sketchybar + borders |

---

## Daily ops

### "I changed a config file, how do I see the change?"

| Edited file | Reload command |
|---|---|
| `~/dotfiles/dot_config/yabai/executable_yabairc` | `chezmoi apply && yabai --restart-service` |
| `~/dotfiles/dot_config/skhd/skhdrc` | `chezmoi apply` (**skhd-zig auto-reloads**, no restart) |
| `~/dotfiles/dot_config/sketchybar/*` | `chezmoi apply && sketchybar --reload` |
| `~/dotfiles/dot_config/borders/executable_bordersrc` | `chezmoi apply && borders --reload` |

**Always edit in `~/dotfiles/dot_config/`, never `~/.config/`.** The latter
gets overwritten on next `chezmoi apply`.

### Reset to clean slate
```sh
yabai --restart-service && skhd --restart-service && \
  brew services restart sketchybar && brew services restart borders
```

Or just: `ctrl + alt + cmd + r`.

### Check what's running
```sh
launchctl list | grep -E "yabai|skhd|sketchybar|borders"
# Real PIDs in column 1 = healthy. "-" = crashed.

yabai -m query --windows   # if this returns JSON, yabai is alive
yabai -m query --displays
yabai -m query --spaces
```

### Logs
```sh
tail -f /tmp/yabai_$(whoami).out.log    # yabai stdout
tail -f /tmp/yabai_$(whoami).err.log    # yabai stderr (often stale)
```
sketchybar/borders use `brew services info <name>` for log paths.

---

## Common situations

| Want to... | Do this |
|---|---|
| Open a new terminal | `alt + return` |
| Have 2 windows side-by-side | Just open them — yabai tiles automatically |
| Make one window dominant | Focus it → `alt + f` |
| Move a window to a different space | `shift + alt + N` *(needs SIP)*, or `alt + t` to float it then drag |
| Stop yabai managing one app | Add `yabai -m rule --add app="^MyApp$" manage=off` to `yabairc` |
| Restart just one tool | `<tool> --restart-service` (yabai/skhd) or `brew services restart <tool>` (sketchybar/borders) |
| Temporarily disable tiling | `yabai --stop-service` — windows behave like normal macOS until you `--start-service` again |
| Hide / show sketchybar | `sketchybar --bar hidden=on` / `hidden=off` |

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Hotkeys don't fire | `launchctl list | grep skhd` — if PID is `-`, check Accessibility. |
| Windows don't tile | Same check for `yabai`. Some apps (System Settings, Calculator, 1Password, Raycast) are intentionally floated — see `yabairc` rules. |
| New window won't tile but old ones do | App is in the float-rules list, or the window is a child/modal (modals always float). |
| Bar shows ▢▢▢ boxes | Nerd font / app font not loaded: `brew install --cask font-jetbrains-mono-nerd-font font-sketchybar-app-font && sketchybar --reload`. |
| Bar disappears entirely | `brew services restart sketchybar`. Check Screen Recording permission. |
| Borders gone | `brew services restart borders`. Same screen recording perm. |
| Focused window is wrong color | Edit `bordersrc` `active_color` (hex 0xAARRGGBB). |
| `shift + alt + N` does nothing for moving windows | That feature requires SIP partially disabled. See [`RICE.md`](./RICE.md) "SIP upgrade path". |
| Tiling looks chaotic after sleep/wake | `ctrl + alt + cmd + r` to reset, or `yabai -m space --balance`. |

---

## Cheat-sheet card (print or screenshot)

```
FOCUS:  alt + h  j  k  l                    ← → up down
SWAP:   shift + alt + h/j/k/l
ZOOM:   alt + f                              (toggle)
ROTATE: alt + r                              90°
BALANCE: alt + e                             equalize splits
FLOAT:  alt + t                              escape tiling
NEW:    alt + return                         Ghostty
SPACE:  alt + 1..9                           focus
        shift + alt + 1..9                   send window [SIP]
RESET:  ctrl + alt + cmd + r                 restart everything
MOUSE:  fn + drag (move), fn + rdrag (resize)
```
