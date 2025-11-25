#!/bin/bash

# --- Find the newest active Cider MPRIS instance ---
player=$(playerctl -l 2>/dev/null | grep chromium | tail -n1)

# If nothing found, show idle state
if [ -z "$player" ]; then
  echo '{"text":"No music","percentage":0}'
  exit 0
fi

# --- Fetch metadata (first attempt) ---
title=$(playerctl -p "$player" metadata title 2>/dev/null)
artist=$(playerctl -p "$player" metadata artist 2>/dev/null)

# If Cider spawned a new MPRIS instance, retry using *oldest* instance
if [ -z "$title" ] && [ -z "$artist" ]; then
  player=$(playerctl -l 2>/dev/null | grep chromium | head -n1)
  title=$(playerctl -p "$player" metadata title 2>/dev/null)
  artist=$(playerctl -p "$player" metadata artist 2>/dev/null)
fi

# --- If still empty, show loading indicator ---
if [ -z "$title" ] && [ -z "$artist" ]; then
  echo '{"text":"…","percentage":0}'
  exit 0
fi

# --- Truncate artist to avoid insane Hamilton-style cast lists ---
maxartist=25
short_artist="$artist"

if [ ${#artist} -gt $maxartist ]; then
  short_artist="${artist:0:$maxartist}…"
fi

# --- Build display text ---
text="$short_artist — $title"

# --- Escape &, otherwise Waybar's GTK markup parser freaks out ---
escaped=$(printf '%s' "$text" | sed 's/&/\&amp;/g')

# --- Fetch progress information ---
pos=$(playerctl -p "$player" position 2>/dev/null)
len=$(playerctl -p "$player" metadata mpris:length 2>/dev/null)

# --- Compute % safely ---
if [ -z "$len" ] || [ "$len" -eq 0 ] 2>/dev/null; then
  percent=0
else
  len_s=$(awk "BEGIN {print $len / 1000000}")
  percent=$(awk "BEGIN {print ($pos / $len_s) * 100}")
fi

# Clamp 0–100 just in case
percent=$(awk "BEGIN {if ($percent < 0) print 0; else if ($percent > 100) print 100; else print $percent}")

# --- JSON encode final string ---
json_text=$(printf '%s' "$escaped" | jq -R -s @json)

# --- Output for Waybar ---
printf '{"text": %s, "percentage": %.0f}\n' "$json_text" "$percent"