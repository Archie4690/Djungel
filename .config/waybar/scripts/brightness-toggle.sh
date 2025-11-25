#!/bin/bash
# ── brightness-toggle.sh ─────────────────────────────
# Description: Cycle monitor brightness between 30%, 60%, and 100%
# Usage: Waybar `custom/brightness` on-click
# Dependencies: ddcutil
# ─────────────────────────────────────────────────────

DISPLAY_NUM="${DDC_DISPLAY:-1}"

# Get current brightness (0–100)
current=$(ddcutil --bus=0 getvcp 10 2>/dev/null \
  | awk -F'=' '/current/ { gsub(/[^0-9]/,"",$2); print $2 }')

ddcutil --bus=0 setvcp 10 "$target" >/dev/null 2>&1


# Sensible fallback
[ -z "$current" ] && current=60

percent="$current"

if [ "$percent" -lt 45 ]; then
  target=60
elif [ "$percent" -lt 85 ]; then
  target=100
else
  target=30
fi

ddcutil --display "$DISPLAY_NUM" setvcp 10 "$target" >/dev/null 2>&1
