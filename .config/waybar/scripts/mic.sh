#!/bin/bash
# ── mic.sh ─────────────────────────────────────────────────
# Description: Shows microphone mute/unmute status with icon
# Usage: Called by Waybar `custom/microphone` module every 1s
# Dependencies: pactl (PulseAudio / PipeWire)
# ───────────────────────────────────────────────────────────


if pactl get-source-mute @DEFAULT_SOURCE@ | grep -q 'yes'; then
  # Muted → mic-off icon
  echo "<span foreground='#ff4453'>[  ]</span>"
else
  # Active → mic-on icon
  echo "<span foreground='#0b5e17'>[  ]</span>"
fi

