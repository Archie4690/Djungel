#!/bin/bash

monitor="$WAYBAR_OUTPUT_NAME"
ws=1

active_on_this_monitor=$(hyprctl monitors -j \
  | jq -r ".[] | select(.name == \"$monitor\").activeWorkspace.id")

if [ "$active_on_this_monitor" -eq "$ws" ]; then
  echo "<span foreground='#0b5e17' letter_spacing='15000' weight='bold'>[1]</span>"
else
  echo "<span foreground='#0b5e17'>[1]</span>"
fi
