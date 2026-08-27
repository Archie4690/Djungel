#!/usr/bin/env bash
# Prints the currently playing track for hyprlock via playerctl.

if ! command -v playerctl >/dev/null 2>&1; then
  exit 0
fi

players=$(playerctl -l 2>/dev/null) || exit 0
if [ -z "$players" ]; then
  exit 0
fi

chosen=""
for p in $players; do
  status=$(playerctl -p "$p" status 2>/dev/null)
  if [ "$status" = "Playing" ]; then
    chosen="$p"
    break
  fi
done

if [ -z "$chosen" ]; then
  chosen=$(printf '%s\n' "$players" | head -n 1)
fi

artist=$(playerctl -p "$chosen" metadata artist 2>/dev/null)
title=$(playerctl -p "$chosen" metadata title 2>/dev/null)

if [ -n "$artist" ] && [ -n "$title" ]; then
  printf '%s — %s\n' "$artist" "$title"
elif [ -n "$title" ]; then
  printf '%s\n' "$title"
fi
