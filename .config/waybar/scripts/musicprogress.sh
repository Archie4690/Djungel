#!/bin/bash
# musicprogress.sh — Cider progress bar for Waybar
# Dependencies: playerctl, awk, bc, seq

# Find latest Chromium-based MPRIS player (Cider)
player=$(playerctl -l 2>/dev/null | grep chromium | tail -n1)

if [ -z "$player" ]; then
  # No player → empty bar
  echo "{\"text\":\"<span foreground='#0b5e17'> [░░░░░░░░░░] 0%</span>\",\"tooltip\":\"No music\"}"
  exit 0
fi

status=$(playerctl -p "$player" status 2>/dev/null || echo "")

# If not playing or paused, show idle bar
if [ "$status" != "Playing" ] && [ "$status" != "Paused" ]; then
  echo "{\"text\":\"<span foreground='#0b5e17'> [░░░░░░░░░░] 0%</span>\",\"tooltip\":\"Idle\"}"
  exit 0
fi

# --- Progress numbers ---
pos=$(playerctl -p "$player" position 2>/dev/null)
len=$(playerctl -p "$player" metadata mpris:length 2>/dev/null)

if [ -z "$len" ] || [ "$len" -eq 0 ] 2>/dev/null; then
  percent=0
else
  # mpris:length is in microseconds → seconds
  len_s=$(awk "BEGIN {print $len / 1000000}")
  percent=$(awk "BEGIN {print ($pos / $len_s) * 100}")
fi

# Clamp 0–100
percent=$(awk "BEGIN {if ($percent < 0) print 0; else if ($percent > 100) print 100; else print $percent}")

# Turn percent into a 10-block bar
filled=$((percent / 10))
empty=$((10 - filled))

bar=$(printf '█%.0s' $(seq 1 $filled))
pad=$(printf '░%.0s' $(seq 1 $empty))
ascii_bar="[$bar$pad]"

# Colour by status / % (tweak to taste)
if [ "$status" = "Paused" ]; then
  fg="#e5c07b"   # gold-ish when paused
elif [ "$(printf "%.0f" "$percent")" -lt 50 ]; then
  fg="#56b6c2"   # teal for first half
else
  fg="#98c379"   # green for second half
fi

# Icon
if [ "$status" = "Paused" ]; then
  icon=""
else
  icon=""
fi

# Tooltip stays simple, no special chars
tooltip="Playback: $status  (${percent}% )"

# Final JSON (markup in text, plain tooltip)
echo "{\"text\":\"<span foreground='$fg'>$icon $ascii_bar $(printf '%.0f' "$percent")%</span>\",\"tooltip\":\"$tooltip\"}"
