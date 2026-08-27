#!/usr/bin/env bash
# Quick visual test of every styled mako state. Run with no args for all,
# or pass a section name: urgency, progress, icon, markup, group, long, modes

set -euo pipefail

urgency() {
  notify-send -u low      "Low urgency"      "Dim text, bevel-grey border, 3s timeout."
  notify-send -u normal   "Normal urgency"   "Teal border on the lighter panel, 6s."
  notify-send -u critical "Critical urgency" "Red 2px border, opaque, 10s and ignores timeout."
}

progress() {
  for v in 25 60 90; do
    notify-send -h int:value:$v -h string:x-canonical-private-synchronous:vol \
      "Volume" "Progress fill at ${v}% — teal overlay."
    sleep 0.7
  done
}

icon() {
  notify-send -i firefox        "With an icon"   "Capped at 32px."
  notify-send -i dialog-warning "Warning icon"   "Stock freedesktop name."
  notify-send                   "No icon"        "Text-only layout for comparison."
}

markup() {
  notify-send "Markup" "<b>bold</b>, <i>italic</i>, <u>underline</u>, <tt>mono</tt>"
}

group() {
  # group-by=app-name,summary — same app+summary collapses into one stack
  for i in 1 2 3; do
    notify-send -a "Grouper" "Same summary" "Body number $i"
    sleep 0.3
  done
}

long() {
  notify-send "Wrapping test" "$(printf 'A very long body that should wrap inside the 360px width and show how padding and line spacing behave across several lines. %.0s' 1 2)"
}

modes() {
  echo "current modes: $(makoctl mode | tr '\n' ' ')"
  echo "--- compact (10pt, 260px) ---"
  makoctl mode -a compact
  notify-send "Compact mode" "Body is hidden here — format is summary only."
  sleep 3; makoctl mode -r compact

  echo "--- focus (light-blue border) ---"
  makoctl mode -a focus
  notify-send "Focus mode" "Border switches to #83a598, 2s timeout."
  sleep 3; makoctl mode -r focus

  echo "--- do-not-disturb (nothing should appear) ---"
  makoctl mode -a do-not-disturb
  notify-send "You should NOT see this" "invisible=1 while DND is active."
  sleep 2; makoctl mode -r do-not-disturb
  echo "restored: $(makoctl mode | tr '\n' ' ')"
  makoctl restore
}

if [ $# -gt 0 ]; then
  "$@"
else
  urgency; sleep 2
  progress; sleep 2
  icon;     sleep 2
  markup;   sleep 2
  group;    sleep 2
  long;     sleep 2
  modes
fi
