#!/usr/bin/env bash
set -euo pipefail

min=1
max=8

sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"
if [ -z "$sig" ]; then
  sig=$(/usr/bin/hyprctl instances | /usr/bin/awk '/^instance /{gsub(":","",$2); print $2; exit}')
fi

if [ -z "$sig" ]; then
  exit 1
fi

id=$(/usr/bin/hyprctl -i "$sig" -j activeworkspace 2>/dev/null | /usr/bin/jq -r '.id' 2>/dev/null || true)
case "$id" in
  ''|*[!0-9]*) exit 1;;
 esac

if [ "$id" -lt "$max" ]; then
  /usr/bin/hyprctl -i "$sig" dispatch movetoworkspace $((id + 1))
fi
