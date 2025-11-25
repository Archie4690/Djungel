#!/bin/bash
# ── brightness.sh ─────────────────────────────────────────
# Description: Shows current brightness with ASCII bar + tooltip
# Usage: Waybar `custom/brightness` every 2s
# Dependencies: ddcutil, seq, printf
# ──────────────────────────────────────────────────────────

# Which monitor to control (ddcutil display index)
# Override with DDC_DISPLAY env var if you like.
DISPLAY_NUM="${DDC_DISPLAY:-1}"

# Get current brightness (0–100) using DDC/CI (VCP 0x10)
current=$(ddcutil --bus=0 getvcp 10 2>/dev/null \
  | awk -F'=' '/current/ { gsub(/[^0-9]/,"",$2); print $2 }')

# Fallback if ddcutil failed
if [ -z "$current" ]; then
  echo '{"text":"☼ [??????????] N/A","tooltip":"Brightness: N/A\nDevice: DDC display not found"}'
  exit 0
fi

percent="$current"

# Build ASCII bar (10 segments)
filled=$((percent / 10))
[ "$filled" -gt 10 ] && filled=10
empty=$((10 - filled))

bar=$(printf '█%.0s' $(seq 1 "$filled"))
pad=$(printf '░%.0s' $(seq 1 "$empty"))
ascii_bar="[$bar$pad]"

# Icon
icon="˖⁺‧₊⟡₊˚⊹"

# Colour thresholds
if [ "$percent" -lt 20 ]; then
  fg="#bf616a"  # red
elif [ "$percent" -lt 55 ]; then
  fg="#fab387"  # orange
else
  fg="#56b6c2"  # cyan
fi

# Tooltip text
tooltip="Brightness: ${percent}%\nDisplay: ${DISPLAY_NUM} (DDC/CI)"

# JSON output
echo "{\"text\":\"<span foreground='${fg}'>${icon} ${ascii_bar} ${percent}%</span>\",\"tooltip\":\"${tooltip}\"}"
