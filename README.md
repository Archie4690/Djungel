# Djungel

Dotfiles for my Arch Linux + Hyprland desktop — a Gruvbox-dark, retro-terminal
setup built around Waybar, kitty and a keyboard-driven workflow.

> **Note on the screenshots below:** Keyboard layout for my Corne split keyboard using Dvorak Programmer layout

<img width="877" height="320" alt="desktop" src="https://github.com/user-attachments/assets/7a98a3ac-5384-4773-9d39-a534be57563c" />
<img width="877" height="323" alt="terminal" src="https://github.com/user-attachments/assets/6d1eede7-39c8-4d87-bd6d-a9d1f7bde849" />
<img width="878" height="322" alt="launcher" src="https://github.com/user-attachments/assets/d1c6cc5b-1c41-4d7d-8ced-6486f8481900" />

## Layout

Each top-level directory is one application. Everything maps onto `~/.config/`
except `home/` (which maps onto `~`) and `bin/` (which maps onto `~/.local/bin`).

```
Djungel/
├── home/          → ~/                  .zshrc, .gitconfig
├── bin/           → ~/.local/bin/       standalone helper scripts
├── hypr/          → ~/.config/hypr/     compositor, lock, idle, wallpaper
├── waybar/        → ~/.config/waybar/   two-monitor powerline status bar
├── kitty/         rofi/  mako/  cava/   terminal, launcher, notifications, visualiser
├── nvim/          tmux/  zsh/           editor, multiplexer, shell
├── btop/  htop/  dooit/  swappy/  fd/  git/  neofetch/
├── scripts/       → ~/.config/scripts/  Minecraft server helpers
├── secrets.example/                     what to put in ~/.config/.secrets/
└── install.sh                           symlinks everything into place
```

## Install

```sh
git clone https://github.com/Archie4690/Djungel ~/.config/Djungel
cd ~/.config/Djungel
./install.sh --dry-run     # see exactly what will change
./install.sh               # link it all
```

`install.sh` symlinks each tracked file to its real location, so the repo *is*
the live config — edit either side, commit from here, and it can never drift.
Anything already in place is moved to `~/.dotfiles-backup/<timestamp>/` first.

Link a subset with `./install.sh hypr waybar kitty`.

## Secrets

Nothing sensitive is tracked. Machine-specific values live in two gitignored
places:

- `~/.config/zsh/secrets.zsh` — env vars sourced by `.zshrc`
  (template: [`zsh/secrets.zsh.example`](zsh/secrets.zsh.example))
- `~/.config/.secrets/` — tokens, hostnames, MAC addresses read by the Waybar
  scripts (see [`secrets.example/README.md`](secrets.example/README.md))

`install.sh` creates both on first run.

## Palette

Gruvbox dark, used consistently across Waybar, kitty, rofi, mako and tmux.

| Role | Hex |
|---|---|
| Background | `#1c1c1c` |
| Surface | `#282828` |
| Foreground | `#ebdbb2` |
| Muted | `#928374` |
| Selection | `#504945` |
| Accent (blue) | `#458588` |
| Accent (light blue) | `#83a598` |
| Warning (yellow) | `#d79921` |
| Error (red) | `#cc241d` |

Font throughout: **DepartureMono Nerd Font**, self made bold and italics. 

## What's configured

| Directory | Notes |
|---|---|
| `hypr` | Hyprland via `hyprland.lua` (the `.conf` is an inert placeholder — see the header comment). Includes hyprlock, hypridle, hyprpaper, a DVD-logo screensaver, and 11 helper scripts for screenshots, workspace stepping, audio switching and now-playing. |
| `waybar` | Two bars, one per monitor, styled as a Neovim powerline statusline. Full breakdown of modules, separators and colour zones in [`waybar/CLAUDE.md`](waybar/CLAUDE.md). |
| `zsh` + `home/.zshrc` | vi mode, custom prompt with git branch, fzf bindings with a shared ignore list, auto-attach to tmux, neofetch on local shells. |
| `tmux` | `C-a` prefix, vi copy-mode to `wl-copy`, Gruvbox status bar. Lives at `~/.config/tmux/tmux.conf` (tmux 3.1+ reads it there natively). |
| `nvim` | lazy.nvim setup — `init.lua` plus `lazy-lock.json` for reproducible plugin versions. |
| `rofi` | drun/run modes with the `retro` theme; Shift+Enter runs a command in kitty. |
| `mako` | Per-urgency styling and three modes: `do-not-disturb`, `compact`, `focus`. |
| `scripts` | Helpers for my Cobblemon/Filament Minecraft servers. |
| `bin` | `rotate-screen`, `switch-profile`, `tmux-sessionizer`. |

## Requirements

**Desktop:** `hyprland` `hyprlock` `hypridle` `hyprpaper` `waybar` `kitty`
`rofi-wayland` `mako` `grim` `slurp` `swappy` `wl-clipboard` `playerctl`
`brightnessctl` `bluez-utils` `ttf-departure-mono-nerd`

**Shell / CLI:** `zsh` `zsh-syntax-highlighting` `zsh-autosuggestions` `tmux`
`neovim` `fzf` `fd` `jq` `yazi` `btop` `htop` `dooit` `cava` `neofetch`

**Optional:** `tailscale` and `wol` (Waybar SSH/wake modules — disable those
modules if unused), `python-gobject` (Waybar media module).
