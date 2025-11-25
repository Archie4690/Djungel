#!/bin/bash

monitor="$WAYBAR_OUTPUT_NAME"
ws=5

active_on_this_monitor=$(hyprctl monitors -j \
  | jq -r ".[] | select(.name == \"$monitor\").activeWorkspace.id")

if [ "$active_on_this_monitor" -eq "$ws" ]; then
  echo "<span foreground='#0b5e17' letter_spacing='15000' weight='bold'>[5]</span>"
else
  echo "<span foreground='#0b5e17'>[5]</span>"
fi
