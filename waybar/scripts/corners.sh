#!/usr/bin/env bash
# Lifetime DVD-logo corner hits, written by the screensaver.
f="${XDG_STATE_HOME:-$HOME/.local/state}/dvd-screensaver/corners"
n=$(cat "$f" 2>/dev/null)
[[ "$n" =~ ^[0-9]+$ ]] || n=0

if [ "$n" -eq 0 ]; then
  tip="No corner hits yet"
else
  tip="$n corner hit$([ "$n" -eq 1 ] || echo s)"
fi
printf '{"text":" %s","tooltip":"%s","class":"corners"}\n' "$n" "$tip"
