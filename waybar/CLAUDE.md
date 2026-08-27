# Waybar Configuration

## Overview
This waybar setup runs two bars — one per monitor — styled as a Neovim/powerline statusline using the Gruvbox dark colour palette.

## Files
- `config.jsonc` — bar definitions for both monitors (layout, heights, module lists)
- `modules.jsonc` — all module definitions (shared between both bars)
- `style.css` — styles for the HDMI-A-1 bar (secondary monitor, 1920px)
- `style-primary.css` — styles for the DP-1 bar (1440p primary monitor, 2560px)
- `scripts/` — helper scripts for updates, github notifications, bluetooth, media, mako, etc.

## Per-bar Styling
The DP-1 bar uses `"style": "/home/archie/.config/waybar/style-primary.css"` in config.jsonc. Note: per-bar style loading has been unreliable with Waybar v0.15.0 — both bars may end up reading `style.css`. This is an open issue.

## Colour Zones (Gruvbox)
| Zone | Hex | Used for |
|---|---|---|
| bar bg | `#1c1c1c` | Bar background, window title, centre modules |
| mid | `#282828` | Network, bluetooth, media, workspace buttons |
| blue | `#458588` | Clock (left accent), audio group (right) |
| lightblue | `#83a598` | Mako/notifications (rightmost, most prominent) |
| foreground | `#ebdbb2` | General text |
| muted | `#928374` | Inactive workspace numbers, rofi label |

## Powerline Separators
Six custom separator modules are defined in `modules.jsonc` using Unicode powerline characters:
- `` (U+E0B0) — right-pointing solid arrow, used in the left panel
- `` (U+E0B2) — left-pointing solid arrow, used in the right panel

| Module | Character | fg | bg | Purpose |
|---|---|---|---|---|
| `custom/sep-blue-mid` | `` | `#458588` | `#282828` | clock → network/bt |
| `custom/sep-mid-bar` | `` | `#282828` | `#1c1c1c` | network/bt → window |
| `custom/sep-bar-mid-r` | `` | `#282828` | `#1c1c1c` | bar → media (DP-1) |
| `custom/sep-mid-blue-r` | `` | `#458588` | `#282828` | media → audio (DP-1) |
| `custom/sep-blue-lightblue-r` | `` | `#83a598` | `#458588` | audio → mako |
| `custom/sep-bar-blue-r` | `` | `#458588` | `#1c1c1c` | bar → audio (HDMI) |

**Important:** these characters must be written via Python/script, not directly pasted into files — they get silently stripped by some editors/tools.

## Module Layout

### Left (both bars)
`clock` → sep → `network` `bluetooth` → sep → `hyprland/window`

### Centre (both bars)
`custom/rofi` | `hyprland/workspaces` | `group/exit` | `custom/updates` | `custom/github`

### Right — DP-1
sep → `custom/media` → sep → `group/audio` → sep → `custom/mako`

### Right — HDMI-A-1
sep → `group/audio` → sep → `custom/mako`

## Font
`DepartureMono Nerd Font` — includes nerd font glyphs for icons and powerline characters. Icons in mixed icon+text modules (pulseaudio, updates, github) use Pango markup with `<span size="xx-large" rise="-3500" weight="normal">` to size the icon independently from the text.

## Known Issues / Notes
- `font-size` values without `px` units (e.g. `font-size: 18`) are treated as px by GTK but generate a deprecation warning — always include `px`
- CSS class names starting with a digit (e.g. `.1440p`) are invalid CSS selectors — the per-bar name was changed to `primary` during development, then abandoned in favour of separate CSS files
- Powerline separator font-size is set larger than the bar height (28–32px) to ensure the arrow fills the full bar height without gaps
